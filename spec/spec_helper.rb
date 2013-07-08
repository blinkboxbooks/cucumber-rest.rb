require "yarjuf"
require "cucumber"
require "httpclient/capture"

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

RFC822_DATE_FORMAT = "%a, %d %b %Y %H:%M:%S GMT"