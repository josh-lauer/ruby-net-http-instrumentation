require "net/http/tracer/version"

module Net
  module HTTP
    module Tracer

      class << self

        attr_reader :tracer_url

        def instrument
          begin
            @tracer_url = URI.parse(ENV['TRACER_INGEST_URL'])
          rescue
            puts "Tracer ingest URL not provided"
            @tracer_url = URI.new
          end

          patch_request
        end

        def patch_request

          ::Net::HTTP.module_eval do
            alias_method :request_original, :request

            def request(req, body = nil, &block)
              res = ''

              if ingest_path?(req)
                # this is probably a request to export spans, so we should ignore it
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
                OpenTracing.global_tracer.start_active_span("#{req.method} #{req.path}", tags: tags) do |scope|
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

            # Make a best effort to see if this is going out to the ingest url
            # Compare path, address, and port
            def ingest_path?(req)
              
              return "#{Tracer.tracer_url.path}?#{Tracer.tracer_url.query}" == req.path && # this should short circuit in most cases
                Tracer.tracer_url.host == @address &&
                Tracer.tracer_url.port == @port
            end
          end
        end
      end
    end
  end
end
