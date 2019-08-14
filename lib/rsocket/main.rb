require 'rubygems'
require 'eventmachine'


module RSocket
  OPTIONS = Hash[:port => 42252, :schema => "tcp", :host => '0.0.0.0']

  module RSocketResponder

    def set(name, value)
      OPTIONS[name] = value
    end
  end

  module RSocketServer

    include RSocketResponder

    def post_init
      puts "-- someone connected to the echo server!"
    end

    def receive_data(data)
      send_data ">>> you sent: #{data}"
      p data.unpack('C*')
    end

  end
end

extend RSocket::RSocketResponder

at_exit do
  EventMachine::run {
    EventMachine::start_server RSocket::OPTIONS[:host],RSocket::OPTIONS[:port], RSocket::RSocketServer
    puts "RSocket Server on #{RSocket::OPTIONS[:port]}"
  }
end