module RSocket

  class Payload
    # @param data [Array<Byte>] data array
    # @param metadata [Array<Byte>] metadata array
    def initialize(data, metadata)
      @data = data
      @metadata = metadata
    end

    def data
      @data
    end

    def metadata
      @metadata
    end

    # @return [String, nil] the contents of our object or nil
    def metadata_utf8
      @metadata.nil? ? nil : @metadata.pack('C*')
    end

    # @return [String, nil] the contents of our object or nil
    def data_utf8
      @data.nil? ? nil : @data.pack('C*')
    end

    # @return [Integer] bytes length
    def bytes_length
      (@data.nil? ? 0 : @data.length) + (@metadata.nil? ? 0 : @metadata.length)
    end
  end

  class ConnectionSetupPayload < Payload
    attr_accessor :metadata_mime_type, :data_mime_type

    def initialize(metadata_mime_type = "text/plain", data_mime_type = "text/plain", data, metadata)
      @metadata_mime_type = metadata_mime_type
      @data_mime_type = data_mime_type
      @data = data
      @metadata = metadata
    end

  end

end

# @param data [Array<Byte>, String]
# @param metadata [Array<Byte>, String]
def payload_of(data, metadata)
  data_bytes = !data.nil? && data.is_a?(String) ? data.unpack('C*') : data
  metadata_bytes = !metadata.nil? && metadata.is_a?(String) ? metadata.unpack('C*') : metadata
  RSocket::Payload.new(data_bytes, metadata_bytes)
end