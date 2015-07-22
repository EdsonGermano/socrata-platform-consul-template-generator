# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'webmock/rspec'
require 'rack'
require 'simplecov'
require 'simplecov-console'

WebMock.disable_net_connect!(allow_localhost: false)
DIR = File.expand_path(File.dirname(__FILE__))

class ConsulApiRack
  def call(env)
    code, ret = 500, 'The tests have changed, fix the rack'
    case env['PATH_INFO']
    when /\/v1\/session\/create/
      code, ret = 200, "{\"ID\": \"test-session-id\"}"
    when /\/v1\/kv\/lock\//
      code, ret = process_lock(env['QUERY_STRING'])
    when /\/v1\/kv\//
      code, ret = process_upload(env['PATH_INFO'])
    end
    [code, { 'Content-Type' => 'application/json' }, [ret]]
  end

  def process_upload(path)
    code, ret = 500, 'The tests have changed, fix the rack'
    case path
    when /^\/v1\/kv\/test-template$/
      code, ret = 200, 'true'
    when /^\/v1\/kv\/test-template-failure$/
      code, ret = 500, 'false'
    end
    return code, ret
  end

  def process_lock(qs)
    code, ret = 500, 'The tests have changed, fix the rack'
    case qs
    when /^acquire=test-session$/
      code, ret = 200, 'true'
    when /^acquire=test-session-lock-fail$/
      code, ret = 200, 'false'
    when /release=test-session/
      code, ret = 200, 'true'
    end
    return code, ret
  end
end

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
  config.before(:each) do
    stub_request(:any, /127.0.0.1:8500\//).
      to_rack(ConsulApiRack.new)
  end

end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console
]
SimpleCov.minimum_coverage(85)
SimpleCov.start

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  #fake.string
end
