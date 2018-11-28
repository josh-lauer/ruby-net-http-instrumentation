require 'bundler/setup'
require 'net/http/tracer'
require 'opentracing_test_tracer'
require 'webmock/rspec'

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
