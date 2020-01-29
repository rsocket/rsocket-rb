require 'rubygems'
require 'rsocket'
require 'rsocket/requester'
require 'rx'


EventMachine.run {
  setup_composite = RSocket::CompositeMetadata.new
  setup_composite.add_wellknown_metadata(:RSOCKET_BEARER_TOKEN, "jwt_token".bytes.to_a)
  rsocket = RSocket.connect("tcp://127.0.0.1:42253", setup_payload: payload_of(nil, setup_composite.to_bytes)) do
    def request_response(payload)
      puts "request_response received: #{payload.data_utf8}"
      Rx::Observable.just(payload_of("data", "metadata"))
    end
  end

  metadata = RSocket::CompositeMetadata.new

  metadata.add_wellknown_metadata(:RSOCKET_MESSAGE_MIMETYPE, RSocket::data_encoding_metadata_byte(:TEXT_PLAIN))
  metadata.add_wellknown_metadata(:RSOCKET_ACCEPT_MIMETYPES, RSocket::accept_encodings_metadata_bytes([:TEXT_PLAIN]))
  rsocket.request_response(payload_of("hello", metadata.to_bytes))
      .subscribe(Rx::Observer.configure do |observer|
        observer.on_next { |payload| puts payload.data_utf8 }
        observer.on_completed { puts "completed" }
        observer.on_error { |error| puts error }
      end)

  # rsocket.fire_and_forget(payload_of("fire","forget"))
}