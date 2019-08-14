module RSocket

  class Payload
    def initialize(data, metadata)
      @data = data
      @metadata = metadata
    end
  end

end

def payload_of(data, metadata)
  RSocket::Payload.new(data, metadata)
end