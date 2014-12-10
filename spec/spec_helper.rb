require "cucumber"

RFC822_DATE_FORMAT = "%a, %d %b %Y %H:%M:%S GMT"
RFC850_DATE_FORMAT = "%A, %d-%b-%y %H:%M:%S GMT"
ANSI_C_DATE_FORMAT = "%a %b %e %H:%M:%S %Y"

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
