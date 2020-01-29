require 'rx'
require 'rsocket/payload'

module RSocket

  module AbstractRSocket

    attr_accessor :onclose
    attr_accessor :attributes

    #@param payload [RSocket::Payload]
    def fire_and_forget(payload)
      puts 'fire_and_forget not implemented'
    end

    #@param payload [RSocket::Payload]
    #@return [Rx::Observable]
    def request_response(payload)
      Rx::Observable.raise_error("request_response not implemented")
    end

    #@param payload [RSocket::Payload]
    #@return [Rx::Observable]
    def request_stream(payload)
      Rx::Observable.raise_error("request_stream not implemented")
    end

    #@@param payloads [Rx::Observable]
    def request_channel(payloads)
      Rx::Observable.raise_error("request_channel not implemented")
    end

    #@param payload [RSocket::Payload]
    def metadata_push(payload)
      puts 'metadata_push not implemented'
    end

    def dispose

    end

  end

  class EmptyAbstractHandler
    include RSocket::AbstractRSocket
  end

end