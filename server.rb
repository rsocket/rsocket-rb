require 'rsocket'
require 'rsocket/server_bootstrap'

set :schema, 'tcp'
set :port, 42252

# @param payload [RSocket::Payload]
#@return [Rx::Observable]
def request_response(payload)
  Rx::Observable.just(payload_of("Hello #{payload.data_utf8}", nil))
end

# @param payload [RSocket::Payload]
#@return [Rx::Observable]
def request_stream(payload)
  print "request/stream called"
  Rx::Observable.from_array([payload_of("first", "metadata"), payload_of("second", "metadata")])
end

# @param payload [RSocket::Payload]
def fire_and_forget(payload)
  print "fire_and_forget"
end

