rsocket-rb
===================

Ruby implementation of [RSocket](http://rsocket.io)


# Installation

Add this line to your application's Gemfile:

```ruby
gem 'rsocket-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rsocket-rb

# How to use?

* RSocket Server with Sinatra style

```ruby
require 'rsocket/server_bootstrap'
require 'rsocket/payload'
require 'rx'

set :schema, 'tcp'
set :port, 42252

# @param payload [RSocket::Payload]
#@return [Rx::Observable]
def request_response(payload)
  puts "request/response called"
  Rx::Observable.just(payload_of("data", "metadata"))
end

```

* RSocket Client

```ruby
require 'rubygems'
require 'eventmachine'
require 'rsocket/requester'
require 'rsocket/payload'
require 'rx'


EventMachine.run {
  #rsocket = EventMachine.connect '127.0.0.1', 1235, AppRequester
  rsocket = RSocket.connect("tcp://127.0.0.1:42252")
  rsocket.request_response(payload_of("request", "response"))
      .subscribe(Rx::Observer.configure do |observer|
        observer.on_next { |payload| puts payload.data_utf8 }
        observer.on_completed { puts "completed" }
        observer.on_error { |error| puts error }
      end)

}
```

# Todo 

#### Transport
 - [x] TCP
 - [ ] Websocket

#### Duplex Socket
 - [x] MetadataPush
 - [x] RequestFNF
 - [x] RequestResponse
 - [x] RequestStream
 - [x] RequestChannel

##### Others
 - [x] Composite Metadata
 - [ ] TCK Test
 - [x] Timeout support
 - [ ] Resume
 - [x] Keepalive
 - [ ] Fragmentation
 - [ ] Cancel
 - [x] Error
 - [ ] Flow Control: RequestN
 - [ ] Flow Control: Lease
 - [x] Load Balance


# References

* RSocket Home: http://rsocket.io/
* EventMachine: fast, simple event-processing library for Ruby programs https://github.com/eventmachine/eventmachine
* RxRuby: https://github.com/ReactiveX/RxRuby