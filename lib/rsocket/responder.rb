require 'rubygems'
require 'logger'
require 'eventmachine'
require 'securerandom'
require 'rsocket/abstract_rsocket'
require 'rsocket/frame'
require 'rsocket/connection'


module RSocket

  $rsocket_options = {}

  module RSocketResponderHandler

    def set(name, value)
      $rsocket_options[name] = value
    end

  end

  class RSocketResponder < RSocket::DuplexConnection
    include RSocketResponderHandler

    attr_accessor :server, :sending_rsocket

    def initialize(server)
      @uuid = SecureRandom.uuid
      @onclose = Rx::Subject.new
      @next_stream_id = 0
      @mode = :SERVER
      @server = server
      @logger = Logger.new(STDOUT)
    end

    def unbind
      @logger.info "#{@uuid} left!"
      @server.connections.delete(self)
    end

    def post_init
      @logger.info "#{@uuid} connected on server!"
      @server.connections << self
      @sending_rsocket = SendingRSocket.new(self)
    end

    #@param setup_frame [RSocket::SetupFrame]
    def receive_setup(setup_frame)
      if RSocketResponder.method_defined? :accept
        setup_payload = ConnectionSetupPayload.new(setup_frame.metadata_encoding, setup_frame.data_encoding, setup_frame.metadata, setup_frame.data)
        @sending_rsocket = accept(setup_payload, @sending_rsocket)
        if @sending_rsocket.nil?
          dispose
        end
      end
    end

    #@param payload_frame [RSocket:PayloadFrame]
    def receive_response(payload_frame)
      # response for send rsocket
      if payload_frame.stream_id % 2 == 1
        @sending_rsocket.receive_response(payload_frame)
      end
    end

    def dispose
      close_connection(true)
      @onclose.on_completed
    end

    def next_stream_id
      @next_stream_id = @next_stream_id + 2
    end


  end

  class SendingRSocket
    include RSocket::AbstractRSocket
    @next_stream_id = -1
    @streams = {}
    @attributes = {}

    def initialize(rsocket_responder)
      @rsocket_responder = rsocket_responder
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

    def fire_and_forget(payload)
      EventMachine.defer(proc {
        fnf_frame = RequestFnfFrame.new(next_stream_id)
        fnf_frame.metadata = payload.metadata
        fnf_frame.data = payload.data
        @rsocket_responder.send_frame(fnf_frame)
      })
    end

    #@param payload [RSocket::Payload]
    #@return [Rx::Observable]
    def request_response(payload)
      request_response_frame = RequestResponseFrame.new(next_stream_id)
      request_response_frame.data = payload.data
      request_response_frame.metadata = payload.metadata
      @rsocket_responder.send_frame(request_response_frame)
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

    def request_stream(payload)
      stream_frame = RequestStreamFrame.new(next_stream_id)
      stream_frame.metadata = payload.metadata
      stream_frame.data = payload.data
      @rsocket_responder.send_frame(stream_frame)
      response_subject = Rx::AsyncSubject.new
      @streams[stream_frame.stream_id] = response_subject
      response_subject
    end

    def request_channel(payloads)
      raise 'request_channel not implemented'
    end

    def metadata_push(payloads)
      if !payload.metadata.nil? && payload.metadata.length > 0
        EventMachine.defer(proc {
          metadata_push_frame = MetadataPushFrame.new
          metadata_push_frame.metadata = payload.metadata
          @rsocket_responder.send_frame(metadata_push_frame)
        })
      end
    end

    def dispose
      @parent.dispose
    end

    def next_stream_id
      begin
        @next_stream_id = @next_stream_id + 2
      end until @streams[@next_stream_id].nil?
      @next_stream_id
    end

  end


  class RSocketServer
    attr_accessor :connections, :option

    def initialize(&block)
      @connections = []
      @option = Hash[:port => 42252, :schema => "tcp", :host => '0.0.0.0']
      self.instance_eval(&block)
    end

    def start
      @signature = EventMachine.start_server(@option[:host], @option[:port], RSocket::RSocketResponder, self)
    end

    def stop
      EventMachine.stop_server(@signature)

      unless wait_for_connections_and_stop
        # Still some connections running, schedule a check later
        EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
      end
    end

    def wait_for_connections_and_stop
      if @connections.empty?
        EventMachine.stop
        true
      else
        puts "Waiting for #{@connections.size} connection(s) to finish ..."
        false
      end
    end
  end

end
