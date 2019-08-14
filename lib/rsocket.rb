require 'rubygems'
require 'eventmachine'

$options = Hash[:port => 42252, :schema => "tcp"]

class Payload
  def initialize(data, metadata)
    @data = data
    @metadata = metadata
  end
end

module RSocketResponder

  def set(option)
    $options[:port] = option[:port]
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

extend RSocketResponder


at_exit do
  EventMachine::run {
    EventMachine::start_server "0.0.0.0", $options[:port], RSocketServer
    puts "RSocket Server on #{$options[:port]}"
  }
end
