require "test_helper"

require 'rsocket/payload'
require 'rsocket/frame'

class FrameTest < Minitest::Test

  def test_framing
    payload = payload_of("data-1".unpack("c*"), "metadata".unpack("c*"))
    frame = RSocket::Frame.new(1, :REQUEST_RESPONSE)
    frame.data = payload.data
    frame.metadata = payload.metadata
    bytes = frame.serialize
    assert_equal bytes, [0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x01, 0x11, 0x00, 0x00, 0x00, 0x08, 0x6d, 0x65, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0x64, 0x61, 0x74, 0x61, 0x2d, 0x31]
  end

  def test_parse
    payload = payload_of("data-1".unpack("c*"), "metadata".unpack("c*"))
    frame = RSocket::Frame.new(1, :REQUEST_RESPONSE)
    frame.metadata = payload.metadata
    frame.data = payload.data
    frame2 = RSocket::Frame.parse(frame.serialize)
    assert_equal frame2.frame_type, frame.frame_type
  end

end