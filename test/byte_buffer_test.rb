require "test_helper"

require 'rsocket/byte_buffer'

class ByteBufferTest < Minitest::Test

  def test_init
    buffer = ByteBuffer.init(3)
    assert_equal 3, buffer.size
  end

  def test_new
    bytes = Array.new(3, 0x11)
    buffer = ByteBuffer.new(bytes)
    assert_equal 3, buffer.size
  end

  def test_put
    buffer = ByteBuffer.new(Array.new(3, 0x11))
    buffer.put 0x12
    assert_equal 0x12, buffer.offset(0)
  end

  def test_put_bytes
    buffer = ByteBuffer.new(Array.new(3, 0x11))
    buffer.put_bytes([0x22, 0x23])
    assert_equal 0x22, buffer.offset(0)
  end

  def test_get_int32
    buffer = ByteBuffer.new([0x00, 0x00, 0x00, 0x01])
    assert_equal 1, buffer.get_int32
    buffer = ByteBuffer.new([0x00, 0x00, 0x02, 0x01])
    assert_equal 2, buffer.get_int24
  end

  def test_array_push
    bytes = Array.new(4, 0x00)
    bytes[1, 2] = [2, 3]
    bytes.push(*[2, 3, 4])
    p bytes
  end

  def test_bit_validation
    byte = 0x10
    assert_equal byte[4], 1
  end


end

