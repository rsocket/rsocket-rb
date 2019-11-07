require 'rsocket/byte_buffer'
require 'rsocket/wellknown_mimetypes'

module RSocket
  class CompositeMetadata
    # @param source [Array]
    def initialize(source = [])
      @source = source
    end

    def to_bytes
      @source
    end

    # convert integer to bytes
    # @param mime_type_id [Integer]
    # @param content [Array]
    def add_wellknown_metadata(mime_type_id, content)
      content_length = content.length
      bytes = Array.new(4 + content_length, 0x00)
      bytes[0] = mime_type_id | 0x80
      bytes[1, 3] = RSocket::ByteBuffer.integer_to_bytes(content_length)[1..3]
      bytes[4, content_length] = content
      @source.push(*bytes)
      self
    end

    # @param mime_type [String]
    # @param content [Array]
    def add_custom_metadata(mime_type, content)
      mime_type_bytes = mime_type.bytes.to_a
      mime_type_length = mime_type_bytes.length
      content_length = content.length
      bytes = Array.new(4 + mime_type_length + content_length, 0x00)
      bytes[0] = mime_type_length
      bytes[1, mime_type_length] = mime_type_bytes
      bytes[mime_type_length + 1, 3] = RSocket::ByteBuffer.integer_to_bytes(content_length)[1..3]
      bytes[mime_type_length + 4, content_length] = content
      @source.push(*bytes)
      self
    end

    # @return [Array<RSocket::CompositeMetadataEntry>]
    def get_all_metadata
      all_metadata = []
      byte_buffer = RSocket::ByteBuffer.new(@source)
      while byte_buffer.has_remaining
        mime_type_id = byte_buffer.get
        if mime_type_id > 0x80
          metadata_length = byte_buffer.get_int24
          metadata_content = byte_buffer.get_bytes(metadata_length)
          all_metadata << RSocket::ReservedMimeTypeEntry.new(mime_type_id - 0x80, metadata_content)
        else
          mime_type_bytes = byte_buffer.get_bytes(mime_type_id)
          metadata_length = byte_buffer.get_int24
          metadata_content = byte_buffer.get_bytes(metadata_length)
          all_metadata << RSocket::ExplicitMimeTypeEntry.new(mime_type_bytes.pack('c*'), metadata_content)
        end
      end
      all_metadata
    end

  end

  class CompositeMetadataEntry
    def get_content

    end

    def get_mime_type

    end
  end

  class ReservedMimeTypeEntry < CompositeMetadataEntry

    def initialize(mime_type_id, content)
      @mime_type = RSocket::WellKnownTypes::MIME_TYPES_BY_ID[mime_type_id].name
      @content = content
    end

    def get_content
      @content
    end

    def get_mime_type
      @mime_type
    end

  end

  class ExplicitMimeTypeEntry < CompositeMetadataEntry

    def initialize(mime_type, content)
      @mime_type = mime_type
      @content = content
    end

    def get_content
      @content
    end

    def get_mime_type
      @mime_type
    end

  end

  class TaggingMetadata

    def initialize(mime_type_entry)
      @source = mime_type_entry.get_content
    end

    def tags
      tags = []
      buffer = RSocket::ByteBuffer.new(@source)
      while buffer.has_remaining
        tag_length = buffer.get
        tags << buffer.get_bytes(tag_length).pack("C*")
      end
      tags
    end
  end

  #@return [ExplicitMimeTypeEntry]
  # @param routing [String]
  def self.routing_metadata(routing, *tags)
    bytes = []
    routing_bytes = routing.unpack("C*")
    bytes.append(routing_bytes.length & 0x7F)
    bytes.append(*routing_bytes)
    tags.each { |tag|
      tag_bytes = tag.unpack("C*")
      bytes.append(tag.length & 0x7F)
      bytes.append(*tag_bytes)
    }
    ReservedMimeTypeEntry.new(0x7E, bytes)
  end

  #@param data_encoding [Symbol]
  #@param accept_encoding [Symbol]
  #@return [Array]
  def self.data_encoding_metadata_bytes(data_encoding, accept_encoding = nil)
    if accept_encoding.nil?
      return [RSocket::WellKnownTypes::MIME_TYPES_BY_SYMBOL[data_encoding].identifier]
    else
      return [RSocket::WellKnownTypes::MIME_TYPES_BY_SYMBOL[data_encoding].identifier,
              RSocket::WellKnownTypes::MIME_TYPES_BY_SYMBOL[accept_encoding].identifier]
    end
  end

end