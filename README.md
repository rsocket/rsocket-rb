rsocket-rb
===================

Ruby implementation of [RSocket](http://rsocket.io)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rsocket-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rsocket-rb

## Usage

* RSocket Server
```
require 'rsocket'

set :schema => 'tcp', :port => 42252


class RSocketResponder < rsocket::AbstractRSocket
    def request_response(payload) do
       # payload
    end
end
```


* RSocket Client

```
require 'rsocket'

client = rsocket.connect().transport("tcp://127.0.0.1:42252").start()
client.request_response(payload("data","metadata"))

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## References

* EventMachine: fast, simple event-processing library for Ruby programs https://github.com/eventmachine/eventmachine
* Yard Cheat Sheet: https://kapeli.com/cheat_sheets/Yard.docset/Contents/Resources/Documents/index