require "test_helper"

require 'rsocket/wellknown_mimetypes'

class WellknownMimeTypeTest < Minitest::Test

  def test_types
    p RSocket::WellKnownTypes::MIME_TYPES_BY_NAME['application/graphql']
    p RSocket::WellKnownTypes::MIME_TYPES_BY_SYMBOL[:APPLICATION_AVRO]
  end
end
