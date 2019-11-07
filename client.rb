require 'rubygems'
require 'eventmachine'
require 'rsocket/requester'
require 'rsocket/payload'
require 'rx'


EventMachine.run {
  rsocket = RSocket.connect("tcp://127.0.0.1:42252") do
    def request_response(payload)
      puts "request_response received: #{payload.data_utf8}"
      Rx::Observable.just(payload_of("data", "metadata"))
    end
  end
  rsocket.request_response(payload_of("request", "response"))
      .subscribe(Rx::Observer.configure do |observer|
        observer.on_next { |payload| puts payload.data_utf8 }
        observer.on_completed { puts "completed" }
        observer.on_error { |error| puts error }
      end)

  # rsocket.fire_and_forget(payload_of("fire","forget"))
}