require './lib/rsocket'
require './lib/rsocket/payload'

set :schema, 'tcp'
set :port, 42253


# RSocket request/response
# @param payload [Payload] rsocket payload
def request_response(payload)
  print "RPC called"
  payload_of("data", "metadata")
end

