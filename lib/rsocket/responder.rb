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

    def dispose
      close_connection(true)
      @onclose.on_completed
    end

    def next_stream_id
      @next_stream_id = @next_stream_id + 2
    end


    class SendingRSocket
      include RSocket::AbstractRSocket

      def initialize(parent)
        @parent = parent
      end

      def fire_and_forget(payload)
        EventMachine.defer(proc {
          fnf_frame = RequestFnfFrame.new(next_stream_id)
          fnf_frame.metadata = payload.metadata
          fnf_frame.data = payload.data
          @parent.send_frame(fnf_frame)
        })
      end

      #@param payload [RSocket::Payload]
      #@return [Rx::Observable]
      def request_response(payload)
        raise 'request_response not implemented'
      end

      def request_stream(payload)
        raise 'request_stream not implemented'
      end

      def request_channel(payloads)
        raise 'request_channel not implemented'
      end

      def metadata_push(payloads)
        if !payload.metadata.nil? && payload.metadata.length > 0
          EventMachine.defer(proc {
            metadata_push_frame = MetadataPushFrame.new
            metadata_push_frame.metadata = payload.metadata
            @parent.send_frame(metadata_push_frame)
          })
        end
      end

      def dispose
        @parent.dispose
      end

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
