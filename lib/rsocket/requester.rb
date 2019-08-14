require 'rubygems'
require 'eventmachine'

module RSocket

  class RSocketRequester < EventMachine::Connection
    def initialize(*args)
      super
      # stuff here...
    end

    def post_init
      send_data('Hello')
    end

    def receive_data(data)
      p data
    end

    def unbind
      p ' connection totally closed'
    end

    def request_response(payload)

    end

    def fire_and_forget(payload)

    end
  end

end