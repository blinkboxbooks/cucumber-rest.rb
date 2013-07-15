require "yarjuf"
require "cucumber"

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

RFC822_DATE_FORMAT = "%a, %d %b %Y %H:%M:%S GMT"

# A mock response class that looks like HttpCapture::Response
class MockResponse
  include Enumerable

  attr_accessor :status
  attr_accessor :body

  def initialize
    @header = {}
  end

  # The default header accessor
  def [](key)
    @header[key]
  end

  # The default header accessor
  def []=(key, value)
    @header[key] = value
  end

  def each(&block)
    @header.each(&block)
  end
end