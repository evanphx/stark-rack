class Stark::Rack
  module ContentNegotiation
    THRIFT_CONTENT_TYPE = 'application/x-thrift'

    def accept_json?(env)
      env['HTTP_ACCEPT'] =~ /^application\/json/
    end

    def headers(env)
      headers = { 'Content-Type' => THRIFT_CONTENT_TYPE }
      if accept_json?(env)
        headers['Content-Type'] = 'application/json'
      end
      headers
    end

    def protocol_factory(env)
      if env['stark.protocol.factory']
        env['stark.protocol.factory']
      else
        if accept_json?(env)
          f = Thrift::JsonProtocolFactory.new
          env['stark.protocol'] = :json
        else
          f = Thrift::BinaryProtocolFactory.new
          env['stark.protocol'] = :binary
        end
        env['stark.protocol.factory'] = f
      end
    end
  end
end
