class Stark::Rack
  module ContentNegotiation
    THRIFT_CONTENT_TYPE = 'application/x-thrift'
    THRIFT_JSON_CONTENT_TYPE = 'application/vnd.thrift+json'

    def accept_json?(env)
      env['HTTP_ACCEPT'] == THRIFT_JSON_CONTENT_TYPE ||
        env['HTTP_CONTENT_TYPE'] == THRIFT_JSON_CONTENT_TYPE
    end

    def headers(env)
      headers = { 'Content-Type' => THRIFT_CONTENT_TYPE }
      if accept_json?(env)
        headers['Content-Type'] = THRIFT_JSON_CONTENT_TYPE
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
