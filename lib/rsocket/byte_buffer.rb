module RSocket

  class ByteBuffer

    attr_reader :reader_index, :writer_index, :capacity

    # create buffer from byte array
    # @param bytes [Array] byte array
    def initialize(bytes)
      @buffer = bytes
      @reader_index = 0
      @writer_index = 0
      @capacity = @buffer.length
    end

    # clear buffer
    def clear
      @buffer.clear
    end

    def is_readable
      @reader_index < @capacity
    end

    def is_writable
      @writer_index < @capacity
    end

    def append(data)
      @buffer.push(*data)
      @writer_index = @reader_index + data.length
      @capacity = @buffer.length
    end

    # get byte
    def get
      if @reader_index < @capacity
        @reader_index = @reader_index + 1
        @buffer[@reader_index - 1]
      end
    end

    def offset(offset)
      @buffer[offset]
    end

    # get bytes
    def get_bytes(len)
      if len > 0
        if @reader_index + len <= @capacity
          @reader_index = @reader_index + len
          @buffer[(@reader_index - len)..(@reader_index - 1)]
        end
      end
    end

    def get_remain
      if @reader_index < @capacity
        offset = @reader_index
        @reader_index = @capacity
        @buffer[offset, @reader_index]
      end
    end

    # get int
    def get_int64
      ByteBuffer.bytes_to_integer(get_bytes(8))
    end

    # get int
    def get_int32
      ByteBuffer.bytes_to_integer(get_bytes(4))
    end

    def get_int24
      ByteBuffer.bytes_to_integer(get_bytes(3))
    end

    def get_int16
      ByteBuffer.bytes_to_integer(get_bytes(2))
    end

    def put(byte)
      @buffer[@pos] = byte
      @writer_index = @reader_index + 1
    end

    # puts bytes
    # @param bytes [Array]
    def put_bytes(bytes)
      bytes.each do |x|
        @buffer[@writer_index] = x
        @writer_index = @writer_index + 1
      end
      @capacity = @buffer.length
    end

    def put_int64(integer)
      ByteBuffer.long_to_bytes(integer).each(&method(:put))
    end

    def put_int32(integer)
      ByteBuffer.integer_to_bytes(integer).each(&method(:put))
    end

    def put_int24(integer)
      ByteBuffer.integer_to_bytes(integer)[1..3].each(&method(:put))
    end

    def put_int16(integer)
      ByteBuffer.integer_to_bytes(integer)[2..3].each(&method(:put))
    end

    def rewind
      @reader_index = 0
      @writer_index = 0
    end

    def reset_reader_index
      @reader_index = 0
    end

    def reset_writer_index
      @writer_index = 0
    end

    def to_s
      @buffer.pack("C*")
    end

    # init a byte buffer with size
    # @param size [Integer]
    def self.init(size)
      bytes = Array.new(size, 0x0)
      ByteBuffer.new(bytes)
    end

    # convert integer to bytes
    # @param i [Integer]
    # @return [Array]
    def self.integer_to_bytes(i)
      bj = Array.new(4, 0x00)
      bj[0] = (i & 0xff000000) >> 24
      bj[1] = (i & 0xff0000) >> 16
      bj[2] = (i & 0xff00) >> 8
      bj[3] = i & 0xff
      bj
    end

    # convert integer to bytes
    # @param i [Integer]
    # @return [Array]
    def self.long_to_bytes(i)
      bj = Array.new(8, 0x00)
      bj[0] = (i & 0xff00000000000000) >> 56
      bj[1] = (i & 0xff000000000000) >> 48
      bj[2] = (i & 0xff0000000000) >> 40
      bj[3] = (i & 0xff00000000) >> 32
      bj[4] = (i & 0xff000000) >> 24
      bj[5] = (i & 0xff0000) >> 16
      bj[6] = (i & 0xff00) >> 8
      bj[7] = i & 0xff
      bj
    end

    # convert bytes to integer
    # @param bytes [Array]
    # @return [Integer]
    def self.bytes_to_integer(bytes)
      integer = 0
      offset = 0
      bytes.reverse.each do |x|
        integer = integer + (x << 8 * offset)
        offset = offset + 1
      end
      integer
    end
  end
end