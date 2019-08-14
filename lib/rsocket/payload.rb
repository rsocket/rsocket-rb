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
      @metadata.nil? ? nil : @metadata.pack('c*')
    end

    # @return [String, nil] the contents of our object or nil
    def data_utf8
      @data.nil? ? nil : @data.pack('c*')
    end

    # @return [Integer] bytes length
    def bytes_length
      (@data.nil? ? 0 : @data.length) + (@metadata.nil? ? 0 : @metadata.length)
    end
  end

end

# @param data [Array<Byte>] data array
# @param metadata [Array<Byte>] metadata array
def payload_of(data, metadata)
  RSocket::Payload.new(data, metadata)
end