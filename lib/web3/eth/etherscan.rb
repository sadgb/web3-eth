module Web3
  module Eth
    class Etherscan

      attr_reader :api_key, :connect_options

      def initialize api_key, api_host = 'api'
        @api_key = api_key
        @api_host = api_host
        @connect_options = build_connect_options
      end

      def method_missing m, *args
        api_module, action = m.to_s.split '_', 2
        raise "Calling method must be in form <module>_<action>" unless action

        arguments = args[0].kind_of?(String) ? { address: args[0] } : args[0]
        result = request api_module, action, arguments

        if connect_options[:parse_result]
          begin
            JSON.parse result
          rescue
            result
          end
        else
          result
        end

      end


      private

      def build_connect_options
        {
          open_timeout: 10,
          read_timeout: 70,
          parse_result: true,
          url: "https://#{@api_host}.etherscan.io/api"
        }
      end

      def request api_module, action, args = {}

        uri = URI connect_options[:url]
        uri.query = URI.encode_www_form({
            module: api_module,
            action: action,
            apikey: api_key
                                        }.merge(args))

        Net::HTTP.start(uri.host, uri.port,
                        connect_options.merge(use_ssl: uri.scheme=='https' )) do |http|

          request = Net::HTTP::Get.new uri
          response = http.request request

          raise "Error code #{response.code} on request #{uri.to_s} #{request.body}" unless response.kind_of? Net::HTTPOK

          json = JSON.parse(response.body)

          raise "Response #{json['message']} on request #{uri.to_s}" unless json['status']=='1'

          json['result']

        end
      end


    end
  end
end