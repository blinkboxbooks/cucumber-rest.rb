require "http_capture"
require "rack"

module Cucumber
  module Rest
    # Helper functions for checking the cacheability of responses.
    module Status

      def self.ensure_status(expected)
        actual = HttpCapture::RESPONSES.last.status
        raise error_message(actual) unless expected === actual
      end

      def self.ensure_status_class(expected)
        min = case expected
              when :informational then 100
              when :success then 200
              when :redirection then 300
              when :client_error then 400
              when :server_error then 500
              end
        ensure_status(min..(min + 99))
      end

      private

      def self.error_message(actual)
        "Request error was '#{Rack::Utils::HTTP_STATUS_CODES[actual]}' (status #{actual})"
      end

    end
  end
end