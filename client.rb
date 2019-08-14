require 'rubygems'
require 'rsocket/requester'

class AppRequester < RSocket::RSocketRequester

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
end

EventMachine.run {
  EventMachine.connect '127.0.0.1', 42253, AppRequester
}