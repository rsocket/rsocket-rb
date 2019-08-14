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
      if @pos + len <= @size
        @pos = @pos + len
        @buffer[(@pos - len)..(@pos - 1)]
      end
    end

    def get_remain
      if @pos <= @size
        @buffer[@pos, @size]
      end
    end

    # get int
    def get_int32
      bytes_to_integer(get_bytes(4))
    end

    def get_int24
      bytes_to_integer(get_bytes(3))
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

    def put_int32(integer)
      integer_to_bytes(integer).each(&method(:put))
    end

    def put_int24(integer)
      integer_to_bytes(integer)[1..3].each(&method(:put))
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
    def integer_to_bytes(i)
      bj = Array.new(4, 0x00)
      bj[0] = (i & 0xff000000) >> 24
      bj[1] = (i & 0xff0000) >> 16
      bj[2] = (i & 0xff00) >> 8
      bj[3] = i & 0xff
      bj
    end

    # convert bytes to integer
    # @param bytes [Array]
    # @return [Integer]
    def bytes_to_integer(bytes)
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