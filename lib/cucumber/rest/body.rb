require 'http_capture'

module Cucumber
  module Rest
    # Helper functions for the handling of response bodies
    module Body
      def self.ensure_empty(response: HttpCapture::RESPONSES.last)
        raise "Request body was not empty:\n #{response.body}" if response.body.size != 0
      end
    end
  end
end
