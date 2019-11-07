module RSocket

  class ByteBuffer

    attr_reader :pos, :size

    # create buffer from byte array
    # @param bytes [Array] byte array
    def initialize(bytes)
      @buffer = bytes
      @pos = 0
      @size = bytes.length
    end

    # clear buffer
    def clear
      @buffer.clear
    end

    def has_remaining
      @pos < @size
    end

    def append(data)
      @buffer.push(*data)
      @size = @buffer.length
    end

    # get byte
    def get
      if @pos < @size
        @pos = @pos + 1
        @buffer[@pos - 1]
      end
    end

    def offset(offset)
      @buffer[offset]
    end

    # get bytes
    def get_bytes(len)
      if len > 0
        if @pos + len <= @size
          @pos = @pos + len
          @buffer[(@pos - len)..(@pos - 1)]
        end
      end
    end

    def get_remain
      if @pos <= @size
        @buffer[@pos, @size]
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
      @pos = @pos + 1
    end

    # puts bytes
    # @param bytes [Array]
    def put_bytes(bytes)
      bytes.each do |x|
        @buffer[@pos] = x
        @pos = @pos + 1
      end
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
      @pos = 0
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