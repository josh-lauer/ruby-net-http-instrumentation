require "net/http/tracer/version"
require "thread"

module Net
  module Http
    module Tracer

      class << self

        attr_accessor :ignore_request

        def instrument(ignore_request: nil)
          @ignore_request = ignore_request

          patch_request
        end

        def patch_request

          ::Net::HTTP.module_eval do
            alias_method :request_original, :request

            def request(req, body = nil, &block)
              res = ''

              if ::Net::Http::Tracer.ignore_request.respond_to?(:call) &&
                 ::Net::Http::Tracer.ignore_request.call

                res = request_original(req, body, &block)
              else
                tags = {
                  "component" => "Net::HTTP",
                  "span.kind" => "client",
                  "http.method" => req.method,
                  "http.url" => req.path,
                  "peer.host" => @address,
                  "peer.port" => @port,
                }
                OpenTracing.global_tracer.start_active_span("net_http.request", tags: tags) do |scope|
                  # inject the trace so it's available to the remote service
                  OpenTracing.inject(scope.span.context, OpenTracing::FORMAT_RACK, req)

                  # call the original request method
                  res = request_original(req, body, &block)

                  # set response code and error if applicable
                  scope.span.set_tag("http.status_code", res.code)
                  scope.span.set_tag("error", true) if res.is_a?(::Net::HTTPClientError)
                end
              end

              res
            end
          end
        end
      end
    end
  end
end
