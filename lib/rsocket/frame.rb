require 'rubygems'
require 'rsocket/byte_buffer'

module RSocket

  MAJOR_VERSION = "1"
  MINOR_VERSION = "0"

  FRAME_TYPES = Hash[:SETUP => 0x01, :LEASE => 0x02, :KEEPALIVE => 0x03,
                     :REQUEST_RESPONSE => 0x04, :REQUEST_FNF => 0x05, :REQUEST_STREAM => 0x06, :REQUEST_CHANNEL => 0x07,
                     :REQUEST_N => 0x08, :CANCEL => 0x09, :PAYLOAD => 0x0A, :ERROR => 0x0B, :METADATA_PUSH => 0x0C,
                     :RESUME => 0x0D, :RESUME_OK => 0x0E, :EXT => 0xFFFF]

  ERROR_CODES = Hash[:INVALID_SETUP => 0x00000001, :UNSUPPORTED_SETUP => 0x00000002, :REJECTED_SETUP => 0x00000003,
                     :REJECTED_RESUME => 0x00000004, :CONNECTION_ERROR => 0x00000101, :CONNECTION_CLOSE => 0x00000102,
                     :APPLICATION_ERROR => 0x00000201, :REJECTED => 0x00000202, :CANCELED => 0x00000203, :INVALID => 0x00000204]
  class Frame

    attr_accessor :frame_type, :stream_id, :payload, :flags

    # @param frame_type [Symbol] frame type
    # @param metadata [Array] rsocket payload
    # @param data [Array] rsocket payload
    # @param stream_id [Integer] rsocket payload
    def initialize(frame_type, metadata, data, stream_id)
      @frame_type = frame_type
      @metadata = metadata
      @data = data
      @stream_id = stream_id
      @flags = 0x0
      if metadata.nil?
        @length = 4 + 2 + data.length
      else
        @length = 4 + 2 + 3 + metadata.length + (data.nil? ? 0 : data.length)
      end
    end

    # @return [Array<Byte>] frame byte array
    def serialize
      bytes = Array.new(@length + 3)
      buffer = RSocket::ByteBuffer.new(bytes)
      buffer.put_int24 @length
      buffer.put_int32 @stream_id
      if @metadata.nil?
        buffer.put(FRAME_TYPES[@frame_type] << 2)
      else
        buffer.put((FRAME_TYPES[@frame_type] << 2) + 1)
      end
      buffer.put @flags
      unless @metadata.nil?
        buffer.put_int24 @metadata.length
        buffer.put_bytes @metadata
      end
      unless @data.nil?
        buffer.put_bytes @data
      end
      bytes
    end

    # @param array [Array<Byte>] frame array
    # @return [Frame] frame
    def self.parse(array)
      buffer = RSocket::ByteBuffer.new(array)
      length = buffer.get_int24
      stream_id = buffer.get_int32
      byte = buffer.get
      frame_type = byte >> 2
      has_metadata = byte % 2
      flags = buffer.get
      metadata = nil
      if has_metadata == 1
        metadata_length = buffer.get_int24
        metadata = buffer.get_bytes metadata_length
      end
      data = buffer.get_remain
      Frame.new(FRAME_TYPES.key(frame_type), metadata, data, stream_id)
    end

  end

  class SetupFrame < Frame

  end


end