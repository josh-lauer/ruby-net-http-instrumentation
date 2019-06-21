# Net::Http::Tracer

This gem automatically traces all requests made with Net::HTTP.

## Supported Versions

- MRI Ruby 2.0 and newer

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nethttp-instrumentation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nethttp-instrumentation

## Usage

Set an OpenTracing-compatible tracer, such as ['jaeger-client'](https://github.com/signalfx/jaeger-client-ruby), as the global tracer.

Before making any requests, configure the tracer:

```ruby
require 'net/http/instrumentation'

Net::Http::Instrumentation.instrument
```

`instrument` takes optional parameters:
- `tracer`: the OpenTracing tracer to use to trace requests. Default: OpenTracing.global_tracer
- `ignore_request`: a bool or block to determine whether or not a given request
- `status_code_errors`: an array of `Net::HTTPResponse` classes that should have error tags added. Default: `[ ::Net::HTTPServerError ]`

`ignore_requests` should be configured to avoid tracing requests from the tracer
if it uses Net::HTTP to send spans. For example:

```ruby
# in the thread sending spans
Thread.current[:http_sender_thread] = true
...

# configure the instrumentation
Net::Http::Instrumentation.instrument(ignore_request: -> { Thread.current[:http_sender_thread] })
```

To remove instrumentation:

```ruby
Net::Http::Instrumentation.remove

The spans will be given a name consisting of the HTTP method and request path.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/opentracing-contrib/net-http-instrumentation.

## License

The gem is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
