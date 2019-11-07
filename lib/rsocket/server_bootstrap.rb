require 'rsocket/responder'


include RSocket::RSocketResponderHandler


at_exit do
  EventMachine::run {
    rsocket_server = RSocket::RSocketServer.new do
      $rsocket_options.each_pair do |key, value|
        @option[key] = value
      end
    end
    rsocket_server.start
    puts "RSocket server started on #{rsocket_server.option[:port]}"
  }
end