require "net/http/instrumentation/version"
require "thread"

module Net
  module Http
    module Instrumentation

      class << self

        attr_accessor :ignore_request, :tracer, :status_codes

        def instrument(tracer: OpenTracing.global_tracer,
                       ignore_request: nil,
                       status_code_errors: [ ::Net::HTTPServerError ])
          @ignore_request = ignore_request
          @tracer = tracer
          @status_codes = status_code_errors

          patch_request if !@instrumented
          @instrumented = true
        end

        def remove
          return if !@instrumented

          ::Net::HTTP.module_eval do
            remove_method :request
            alias_method :request, :request_original
            remove_method :request_original
          end

          @instrumented = false
        end

        def patch_request

          ::Net::HTTP.module_eval do
            alias_method :request_original, :request

            def request(req, body = nil, &block)
              res = ''

              if ::Net::Http::Instrumentation.ignore_request.respond_to?(:call) &&
                 ::Net::Http::Instrumentation.ignore_request.call(req)

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
                ::Net::Http::Instrumentation.tracer.start_active_span("net_http.request", tags: tags) do |scope|
                  # inject the trace so it's available to the remote service
                  OpenTracing.inject(scope.span.context, OpenTracing::FORMAT_RACK, req)

                  # call the original request method
                  res = request_original(req, body, &block)

                  # set response code and error if applicable
                  scope.span.set_tag("http.status_code", res.code)
                  scope.span.set_tag("error", true) if ::Net::Http::Instrumentation.status_codes.any? { |e| res.is_a? e }
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
