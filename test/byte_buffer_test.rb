require "test_helper"

require 'byte_buffer'

class ByteBufferTest < Minitest::Test

  def test_init
    buffer = ByteBuffer.init(3)
    puts buffer.size
  end

  def test_new
    bytes = Array.new(3, 0x11)
    buffer = ByteBuffer.new(bytes)
    puts buffer.size
  end

  def test_get
    buffer = ByteBuffer.new(Array.new(3, 0x11))
    buffer.put 0x12
    puts buffer.offset(0)
  end

  def test_put_bytes
    buffer = ByteBuffer.new(Array.new(3, 0x11))
    buffer.put_bytes(Array.new(2, 0x22))
    puts buffer.offset(1)
  end

  def test_get_int32
    buffer = ByteBuffer.new([0x00, 0x00, 0x00, 0x01])
    assert_equal(1, buffer.get_int32)
    buffer = ByteBuffer.new([0x00, 0x00, 0x02, 0x01])
    assert_equal(2, buffer.get_int24)
  end
end

