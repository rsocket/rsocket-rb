require 'rubygems'
require 'eventmachine'
require 'rsocket/abstract_rsocket'
require 'rsocket/connection'
require 'rsocket/frame'
require 'rsocket/payload'
require 'uri'
require 'rx'
require 'securerandom'

module RSocket

  class RSocketRequester < RSocket::DuplexConnection
    include RSocket::AbstractRSocket

    #@param resp_handler_block [Proc]
    def initialize(metadata_encoding, data_encoding, setup_payload, resp_handler_block)
      @uuid = SecureRandom.uuid
      @metadata_encoding = metadata_encoding
      @data_encoding = data_encoding
      @setup_payload = setup_payload
      @next_stream_id = -1
      @mode = :CLIENT
      @onclose = Rx::Subject.new
      @streams = {}
      if resp_handler_block.nil?
        @responder_handler = RSocket::EmptyAbstractHandler.new
      else
        @responder_handler = Struct.new(:data_encoding).new(@data_encoding)
        @responder_handler.instance_eval(&resp_handler_block)
      end

    end

    def post_init
      setup_frame = SetupFrame.new(0)
      setup_frame.metadata_encoding = @metadata_encoding
      setup_frame.data_encoding = @data_encoding
      unless @setup_payload.nil?
        setup_frame.metadata = @setup_payload.metadata
        setup_frame.data = @setup_payload.data
      end
      send_frame(setup_frame)
    end

    def unbind
      @onclose.on_completed
    end

    def dispose
      close_connection(true)
    end

    #@param payload_frame [RSocket:PayloadFrame]
    def receive_response(payload_frame)
      stream_id = payload_frame.stream_id
      #error frame type
      if payload_frame.frame_type == :ERROR
        subject = @streams.delete(stream_id)
        unless subject.nil?
          subject.on_error(payload_frame.error_code)
        end
      end
      if payload_frame.is_completed
        subject = @streams.delete(stream_id)
        unless subject.nil?
          subject.on_next(payload_of(payload_frame.data, payload_frame.metadata))
          subject.on_completed
        end
      else
        subject = @streams[stream_id]
        unless subject.nil?
          subject.on_next(payload_of(payload_frame.data, payload_frame.metadata))
        end
      end
    end

    def request_response(payload)
      request_response_frame = RequestResponseFrame.new(next_stream_id)
      request_response_frame.data = "Hello".unpack("C*")
      request_response_frame.metadata = "metadata".unpack("C*")
      send_frame(request_response_frame)
      response_subject = Rx::AsyncSubject.new
      stream_id = request_response_frame.stream_id
      @streams[request_response_frame.stream_id] = response_subject
      # add timeout support because rxRuby without timeout operator
      # todo make it configurable
      EventMachine::Timer.new(15) do
        subject = @streams.delete(stream_id)
        unless subject.nil?
          subject.on_error("Timeout: 15s")
        end
      end
      response_subject
    end

    #@param payload [RSocket::Payload]
    def fire_and_forget(payload)
      EventMachine.defer(proc {
        fnf_frame = RequestFnfFrame.new(next_stream_id)
        fnf_frame.metadata = payload.metadata
        fnf_frame.data = payload.data
        send_frame(fnf_frame)
      })
    end

    def request_stream(payload)
      stream_frame = RequestStreamFrame.new(next_stream_id)
      stream_frame.metadata = payload.metadata
      stream_frame.data = payload.data
      response_subject = Rx::AsyncSubject.new
      @streams[stream_frame.stream_id] = response_subject
      response_subject
    end

    def request_channel(payloads)
      raise 'request_channel not implemented'
    end

    #@param payload [RSocket::Payload]
    def metadata_push(payload)
      if !payload.metadata.nil? && payload.metadata.length > 0
        EventMachine.defer(proc {
          metadata_push_frame = MetadataPushFrame.new
          metadata_push_frame.metadata = payload.metadata
          send_frame(metadata_push_frame)
        })
      end
    end


    def next_stream_id
      begin
        @next_stream_id = @next_stream_id + 2
      end until @streams[@next_stream_id].nil?
      @next_stream_id
    end
  end

  def self.connect(rsocket_uri, metadata_encoding = "message/x.rsocket.composite-metadata.v0", data_encoding = "text/plain", setup_payload = nil, &resp_handler_block)
    uri = URI.parse(rsocket_uri)
    EventMachine::connect uri.hostname, uri.port, RSocketRequester, metadata_encoding, data_encoding, setup_payload, resp_handler_block
  end

end