require "test_helper"

require 'rsocket/payload'

class PayloadTest < Minitest::Test

  def test_creation
    payload = payload_of([100, 97, 116, 97], [109, 101, 116, 97, 100, 97, 116, 97])
    print payload.data_utf8
    print payload.metadata_utf8
    assert_equal "data", payload.data_utf8
  end

  def test_length
    payload = payload_of([100, 97, 116, 97], [109, 101, 116, 97, 100, 97, 116, 97])
    assert_equal 12, payload.bytes_length
    payload = payload_of(nil, [109, 101, 116, 97, 100, 97, 116, 97])
    assert_equal 8, payload.bytes_length
  end

  def test_parse_setup_payload
    setup_payload = [0, 0, 43, 0, 0, 0, 0, 5, 0, 0, 1, 0, 0, 0, 0, 117, 48, 0, 1, 95, 144, 10, 116, 101, 120, 116, 47, 112, 108, 97, 105, 110, 10, 116, 101, 120, 116, 47, 112, 108, 97, 105, 110, 0, 0, 0]

  end

  def test_parse_request_response
    payload = [0, 0, 23, 0, 0, 0, 1, 17, 0, 0, 0, 8, 109, 101, 116, 97, 100, 97, 116, 97, 100, 97, 116, 97, 45, 49]
  end

  def test_string_payload
    payload = payload_of("data", "metadata")
    p payload
  end
end

