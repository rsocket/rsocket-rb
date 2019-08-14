require 'rubygems'
require 'eventmachine'

$options = Hash[:port => 42252, :schema => "tcp", :host => '0.0.0.0']

module RSocket


  module RSocketResponder

    def set(name, value)
      $options[name] = value
    end
  end

  module RSocketServer

    include RSocketResponder

    def post_init
      puts "-- someone connected to the echo server!"
    end

    def receive_data(data)
      send_data ">>> you sent: #{data}"
      request_response data.unpack('C*')
    end

  end
end


extend RSocket::RSocketResponder


at_exit do
  EventMachine::run {
    EventMachine::start_server $options[:host], $options[:port], RSocket::RSocketServer
    puts "RSocket Server on #{$options[:port]}"
  }
end