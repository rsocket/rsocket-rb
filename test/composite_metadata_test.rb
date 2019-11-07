require "test_helper"

require 'rsocket/composite_metadata'


class CompositeMetadataTest < Minitest::Test

  def test_create
    composite_metadata = RSocket::CompositeMetadata.new
    composite_metadata.add_wellknown_metadata(0x01, "demo".bytes.to_a)
    composite_metadata.add_custom_metadata("a/b", "info".bytes.to_a)
    p composite_metadata
    p composite_metadata.get_all_metadata
  end


  def test_routing
    routing_metadata = RSocket::routing_metadata("com.foobar.UserService")
    assert_equal "com.foobar.UserService", RSocket::TaggingMetadata.new(routing_metadata).tags[0]
  end
end