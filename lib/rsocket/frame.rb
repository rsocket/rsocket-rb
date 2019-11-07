require 'rubygems'
require 'rsocket/byte_buffer'

module RSocket

  MAJOR_VERSION = 1
  MINOR_VERSION = 0

  FRAME_TYPES = Hash[:SETUP => 0x01, :LEASE => 0x02, :KEEPALIVE => 0x03,
                     :REQUEST_RESPONSE => 0x04, :REQUEST_FNF => 0x05, :REQUEST_STREAM => 0x06, :REQUEST_CHANNEL => 0x07,
                     :REQUEST_N => 0x08, :CANCEL => 0x09, :PAYLOAD => 0x0A, :ERROR => 0x0B, :METADATA_PUSH => 0x0C,
                     :RESUME => 0x0D, :RESUME_OK => 0x0E, :EXT => 0xFFFF]

  class Frame
    attr_accessor :frame_type, :stream_id, :flags, :metadata, :data

    # @param frame_type [Symbol] frame type
    # @param stream_id [Integer] rsocket payload
    def initialize(stream_id, frame_type)
      @stream_id = stream_id
      @frame_type = frame_type
      @metadata = nil
      @data = nil
      @flags = 0x00
    end

    # @return [Array<Byte>] frame byte array
    def serialize
      has_metadata = !@metadata.nil? && @metadata.length > 0
      metadata_length = has_metadata ? @metadata.length : 0
      frame_length = 4 + 2 + (has_metadata ? metadata_length + 3 : 0) + (@data.nil? ? 0 : @data.length)
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(@stream_id)
      frame_type_byte = FRAME_TYPES[@frame_type] << 2
      buffer.put(frame_type_byte | (has_metadata ? 0x01 : 0x00))
      buffer.put(flags)
      if has_metadata
        buffer.put_int24(metadata_length)
        buffer.put_bytes(@metadata)
      end
      if !@data.nil? && @data.length > 0
        buffer.put_bytes(@data)
      end
      bytes
    end

    # @param array [Array<Byte>] frame array
    # @return [Frame] frame
    def self.parse(array)
      buffer = RSocket::ByteBuffer.new(array)
      frame_length = buffer.get_int24
      stream_id = buffer.get_int32
      byte = buffer.get
      frame_type = byte >> 2
      flags = buffer.get
      has_metadata = (byte & 0x01) == 1
      frame = nil
      case FRAME_TYPES.key(frame_type)
      when :SETUP
        frame = SetupFrame.new(flags)
        frame.parse_header(buffer)
      when :LEASE
        frame = LeaseFrame.new
        frame.parse_header(buffer)
      when :KEEPALIVE
        frame = KeepAliveFrame.new(flags)
        frame.parse_header(buffer)
      when :REQUEST_RESPONSE
        frame = RequestResponseFrame.new(stream_id)
      when :REQUEST_FNF
        frame = RequestFnfFrame.new(stream_id)
      when :REQUEST_STREAM
        frame = RequestStreamFrame.new(stream_id)
        frame.parse_header(buffer)
      when :REQUEST_CHANNEL
        frame = RequestChannelFrame.new(stream_id)
        frame.parse_header(buffer)
      when :REQUEST_N
        frame = RequestNFrame.new(stream_id)
        frame.parse_header(buffer)
      when :CANCEL
        frame = CancelFrame.new(stream_id)
      when :PAYLOAD
        frame = PayloadFrame.new(stream_id, flags)
      when :METADATA_PUSH
        frame = MetadataPushFrame.new
      else
        # type code here
      end
      unless frame.nil?
        if has_metadata
          metadata_length = buffer.get_int24
          frame.metadata = buffer.get_bytes(metadata_length)
        end

        if buffer.has_remaining
          frame.data = buffer.get_remain
        end
      end
      return frame
    end

  end

  class SetupFrame < Frame

    attr_accessor :metadata_encoding, :data_encoding, :resume_token

    def initialize(flags)
      super(0, :SETUP)
      @flags = flags
      @major_version = RSocket::MAJOR_VERSION
      @minor_version = RSocket::MINOR_VERSION
      @keepalive_time = 3000
      @max_life_time = 0x7FFFFFFF
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @major_version = buffer.get_int16
      @minor_version = buffer.get_int16
      @keepalive_time = buffer.get_int32
      @max_life_time = buffer.get_int32
      if @flags & 0x80 == 1
        @resume_token = buffer.get_bytes(buffer.get_int16)
      end
      @metadata_encoding = buffer.get_bytes(buffer.get).pack('c*')
      @data_encoding = buffer.get_bytes(buffer.get).pack('c*')
    end

    def serialize
      # without token
      has_metadata = !@metadata.nil? && @metadata.length > 0
      metadata_length = has_metadata ? @metadata.length : 0
      data_length = @data.nil? ? 0 : @data.length
      frame_length = 6 + 2 + 2 + 4 + 4 + @metadata_encoding.length + 1 + @data_encoding.length + 1 + (has_metadata ? metadata_length + 3 : 0) + data_length
      bytes = Array.new(3 + frame_length, 0x00)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(0)
      buffer.put((0x01 << 2) | (has_metadata ? 0x01 : 0x00))
      buffer.put(0) # todo resume + lease
      buffer.put_int16(@major_version)
      buffer.put_int16(@minor_version)
      buffer.put_int32(@keepalive_time)
      buffer.put_int32(@max_life_time)
      #ignore resume token
      buffer.put(@metadata_encoding.length & 0xFF)
      buffer.put_bytes(@metadata_encoding.unpack("c*"))
      buffer.put(@data_encoding.length & 0xFF)
      buffer.put_bytes(@data_encoding.unpack("c*"))
      if has_metadata
        buffer.put_int24(metadata_length)
        buffer.put_bytes(@metadata)
      end
      if !@data.nil? && @data.length > 0
        buffer.put_bytes(@data)
      end
      bytes
    end

  end

  class LeaseFrame < Frame
    def initialize
      super(0, :LEASE)
      @time_to_live = 0
      @number_if_request = 0
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @time_to_live = buffer.get_int32
      @number_if_request = buffer.get_int32
    end

  end

  class KeepAliveFrame < Frame
    attr_accessor :last_received_position, :flags

    def initialize(flags)
      super(0, :KEEPALIVE)
      @last_received_position = 0
      @flags = flags
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @last_received_position = buffer.get_int64
    end

    def serialize
      frame_length = 14
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(0)
      buffer.put(0x03 << 2)
      buffer.put(@flags)
      buffer.put_int64(@last_received_position)
      bytes
    end

  end

  class RequestResponseFrame < Frame
    def initialize(stream_id)
      super(stream_id, :REQUEST_RESPONSE)
      @flags = 0
    end

    def serialize
      has_metadata = !@metadata.nil? && @metadata.length > 0
      frame_length = 4 + 2 + (has_metadata ? @metadata.length + 3 : 0) + (@data.nil? ? 0 : @data.length)
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(@stream_id)
      buffer.put(0x04 << 2 | (has_metadata ? 0x01 : 0x00))
      buffer.put(@flags)
      if has_metadata
        buffer.put_int24(@metadata.length)
        buffer.put_bytes(@metadata)
      end
      unless @data.nil?
        buffer.put_bytes(@data)
      end
      bytes
    end

  end

  class RequestFnfFrame < Frame
    def initialize(stream_id)
      super(stream_id, :REQUEST_FNF)
    end
  end

  class RequestStreamFrame < Frame
    def initialize(stream_id)
      super(stream_id, :REQUEST_STREAM)
      @initial_request_num = 0x7FFFFFFF
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @initial_request_num = buffer.get_int32
    end

    def serialize
      has_metadata = !@metadata.nil? && @metadata.length > 0
      data_length = @data.nil? ? 0 : @data.length
      frame_length = 10 + (has_metadata ? 3 + @metadata.length : 0) + data_length
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(@stream_id)
      buffer.put(((0x06 << 2) | (has_metadata ? 0x01 : 0x00)))
      buffer.put(0)
      buffer.put_int32(@initial_request_num)
      if has_metadata
        buffer.put_int24(@metadata.length)
        buffer.put_bytes(@metadata)
      end
      if !@data.nil? && @data.length > 0
        buffer.put_bytes(@data)
      end
      bytes
    end
  end

  class RequestChannelFrame < Frame
    def initialize(stream_id)
      super(stream_id, :REQUEST_CHANNEL)
      @initial_request_num = 0
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @initial_request_num = buffer.get_int32
    end
  end

  class RequestNFrame < Frame
    def initialize(stream_id)
      super(stream_id, :REQUEST_N)
      @initial_request_num = 0
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @initial_request_num = buffer.get_int32
    end

    def serialize
      bytes = Array.new(3 + 10, 0x00)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(10)
      buffer.put_int32(@stream_id)
      buffer.put(0x08 << 2)
      buffer.put(@flags)
      buffer.put_int32(@initial_request_num)
      bytes
    end
  end

  class CancelFrame < Frame
    def initialize(stream_id)
      super(stream_id, :CANCEL)
    end

    def serialize
      bytes = Array.new(3 + 6, 0x00)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(6)
      buffer.put_int32(@stream_id)
      buffer.put(0x09 << 2)
      buffer.put(0)
      bytes
    end
  end

  class PayloadFrame < Frame
    def initialize(stream_id, flags)
      super(stream_id, :PAYLOAD)
      @flags = flags
    end

    def is_completed
      @flags[6] == 1
    end

    def serialize
      if @metadata.nil? && @data.nil?
        bytes = Array.new(3 + 6, 0x00)
        buffer = RSocket::ByteBuffer.new(bytes)
        buffer.put_int24(6)
        buffer.put_int32(@stream_id)
        buffer.put(0x0A << 2)
        buffer.put(@flags)
        bytes
      else
        has_metadata = !@metadata.nil? && @metadata.length > 0
        metadata_length = has_metadata ? @metadata.length : 0
        data_length = @data.nil? ? 0 : @data.length
        frame_length = 6 + (has_metadata ? 3 + metadata_length : 0) + data_length
        bytes = Array.new(3 + frame_length)
        buffer = RSocket::ByteBuffer.new(bytes)
        buffer.put_int24(frame_length)
        buffer.put_int32(@stream_id)
        buffer.put(((0x0A << 2) | (has_metadata ? 0x01 : 0x00)))
        buffer.put(@flags)
        if has_metadata
          buffer.put_int24(metadata_length)
          buffer.put_bytes(@metadata)
        end
        if !@data.nil? && @data.length > 0
          buffer.put_bytes(@data)
        end
        bytes
      end
    end
  end

  class ErrorFrame < Frame
    attr_accessor :error_code, :error_data

    def initialize(stream_id)
      super(stream_id, :ERROR)
      @error_code = 0
      @error_data = []
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @error_code = buffer.get_int32
    end

    def serialize
      frame_length = 4 + 2 + 3 + @error_data.length
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(@stream_id)
      buffer.put(0x0B << 2)
      buffer.put(0x00)
      buffer.put_int32(@error_code)
      buffer.put_bytes(@error_data)
      bytes
    end
  end

  class MetadataPushFrame < Frame
    def initialize
      super(0, :METADATA_PUSH)
    end

    def serialize
      frame_length = 4 + 2 + @metadata.length
      bytes = Array.new(3 + frame_length)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24(frame_length)
      buffer.put_int32(0)
      buffer.put((0x0C << 2) | 0x01)
      buffer.put(0x00)
      buffer.put_bytes(@metadata)
      bytes
    end
  end

  class ResumeFrame < Frame
    attr_accessor :token, :last_received_position, :first_available_position

    def initialize
      super(0, :RESUME)
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @major_version = buffer.get_int16
      @minor_version = buffer.get_int16
      @token_length = buffer.get_int16
      @token = buffer.get_bytes(@token_length).pack('c*')
      @last_received_position = buffer.get_int64
      @first_available_position = buffer.get_int64
    end

  end

  class ResumeOkFrame < Frame

    def initialize
      super(0, :RESUME_OK)
    end

    #@param buffer [RSocket::ByteBuffer]
    def parse_header(buffer)
      @last_received_position = buffer.get_int64
    end

  end

  class ExtFrame < Frame
    def initialize
      super(0, :EXT)
    end
  end


end