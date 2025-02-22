module Web3
  module Eth

    class Rpc

      require 'json'
      require 'net/http'

      JSON_RPC_VERSION = '2.0'

      DEFAULT_CONNECT_OPTIONS = {
          use_ssl: false,
          open_timeout: 10,
          read_timeout: 70
      }

      DEFAULT_HOST = 'localhost'
      DEFAULT_PORT = 8545
      DEFAULT_BLOCK = 'latest'

      attr_reader :eth, :connect_options
      attr_accessor :block

      def initialize host: DEFAULT_HOST, port: DEFAULT_PORT, connect_options: DEFAULT_CONNECT_OPTIONS, block: DEFAULT_BLOCK

        @client_id = Random.rand 10000000

        @uri = URI((connect_options[:use_ssl] ? 'https' : 'http')+ "://#{host}#{connect_options[:rpc_path]}")
        @connect_options = connect_options

        @eth = EthModule.new self
        @block = block
      end

      def trace
        @trace ||= TraceModule.new(self)
      end

      def parity
        @parity ||= ParityModule.new(self)
      end

      def debug
        @debug ||= Debug::DebugModule.new(self)
      end

      def request method, params = nil

        headers = @connect_options[:headers] || {"Content-Type" => "application/json"}

        Net::HTTP.start(@uri.host, @uri.port, @connect_options) do |http|

          request = Net::HTTP::Post.new @uri, headers
          request.body = {:jsonrpc => JSON_RPC_VERSION, method: method, params: params, id: @client_id}.compact.to_json
          response = http.request request

          raise "Error code #{response.code} on request #{@uri.to_s} #{request.body}" unless response.kind_of? Net::HTTPOK

          body = JSON.parse(response.body, max_nesting: 1500)

          if body['result']
            body['result']
          elsif body['error']
            raise "Error #{@uri.to_s} #{body['error']} on request #{@uri.to_s} #{request.body}"
          else
            raise "No response on request #{@uri.to_s} #{request.body}"
          end

        end

      end


    end
  end
end

unless Hash.method_defined?(:compact)
  class Hash
    def compact
      self.reject{ |_k, v| v.nil? }
    end
  end
end
