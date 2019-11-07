require 'rubygems'
require 'eventmachine'
require 'rsocket/error_type'
require 'rsocket/frame'

module RSocket

  class DuplexConnection < EventMachine::Connection

    attr_accessor :mode, :responder_handler, :uuid

    def receive_data(data)
      frame_bytes = data.unpack('C*')
      if frame_bytes.length >= 12
        receive_frame_bytes(frame_bytes)
      end
    end

    def send_frame(frame)
      send_data(frame.serialize.pack('C*'))
    end

    def receive_frame_bytes(frame_bytes)
      frame = Frame.parse(frame_bytes)
      unless frame.nil?
        case frame.frame_type
        when :SETUP
          receive_setup(frame)
        when :REQUEST_RESPONSE, :REQUEST_FNF, :REQUEST_STREAM, :REQUEST_CHANNEL, :METADATA_PUSH
          receive_request(frame)
        when :PAYLOAD, :ERROR
          receive_response(frame)
        when :CANCEL
          # cancel logic
        when :REQUEST_N
          # request N
        when :KEEPALIVE
          # Respond with KEEPALIVE
          if flags[7] == 1
            frame_bytes[8] = 0
            send_data(frame_bytes.pack('C*'))
          end
        else
          # type code here
        end
      end
    end

    def receive_setup(setup_frame)

    end

    def receive_response(payload_frame)
      raise "not implemented for message pair"
    end

    def receive_request(frame)
      request_payload = Payload.new(frame.data, frame.metadata)
      case frame.frame_type
      when :REQUEST_RESPONSE
        mono = (@mode == :SERVER) ? request_response(request_payload) : @responder_handler.request_response(request_payload)
        mono.subscribe(
            lambda { |payload|
              payload_frame = PayloadFrame.new(frame.stream_id, 0x40)
              payload_frame.data = payload.data
              payload_frame.metadata = payload.metadata
              send_frame(payload_frame)
            },
            lambda { |error|
              error_frame = ErrorFrame.new(frame.stream_id)
              error_frame.error_code = RSocket::ErrorType::APPLICATION_ERROR
              error_frame.error_data = error.to_s.unpack("C*")
              send_frame(error_frame)
            },
            lambda {

            })
      when :REQUEST_FNF
        EventMachine.defer(proc {
          (@mode == :SERVER) ? fire_and_forget(request_payload) : @responder_handler.fire_and_forget(request_payload)
        })
      when :REQUEST_STREAM
        flux = (@mode == :SERVER) ? request_stream(request_payload) : @responder_handler.request_stream(request_payload)
        flux.subscribe(
            lambda { |payload|
              payload_frame = PayloadFrame.new(frame.stream_id, 0x20)
              payload_frame.data = payload.data
              payload_frame.metadata = payload.metadata
              send_frame(payload_frame)
            },
            lambda { |error|
              error_frame = ErrorFrame.new(frame.stream_id)
              error_frame.error_code = RSocket::ErrorType::APPLICATION_ERROR
              error_frame.error_data = error.to_s.unpack("C*")
              send_frame(error_frame)
            },
            lambda {
              payload_frame = PayloadFrame.new(frame.stream_id, 0x40)
              send_frame(payload_frame)
            })
      when :REQUEST_CHANNEL
        raise "request channel not implemented"
      when :METADATA_PUSH
        EventMachine.defer(proc {
          (@mode == :SERVER) ? metadata_push(request_payload) : @responder_handler.metadata_push(request_payload)
        })
      else
        ## error
      end
    end

    def next_stream_id
      raise "next stream id not implemented"
    end

  end

end
