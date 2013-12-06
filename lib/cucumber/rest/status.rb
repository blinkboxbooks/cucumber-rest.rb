require "http_capture"
require "rack"

module Cucumber
  module Rest
    # Helper functions for checking the cacheability of responses.
    module Status

      def self.ensure_status(expected, response: HttpCapture::RESPONSES.last)
        actual = response.status
        unless expected == actual
          actual_name = Rack::Utils::HTTP_STATUS_CODES[actual]
          expected_name = Rack::Utils::HTTP_STATUS_CODES[expected]
          message = "Request status was #{actual} #{actual_name}; expected #{expected} #{expected_name}"
          raise message
        end
      end

      def self.ensure_status_class(expected, response: HttpCapture::RESPONSES.last)
        min = case expected
              when :informational then 100
              when :success then 200
              when :redirection then 300
              when :client_error then 400
              when :server_error then 500
              end
        max = min + 99
        expected_range = min..max
        actual = response.status
        unless expected_range === actual
          message = "Request status was #{actual} #{Rack::Utils::HTTP_STATUS_CODES[actual]}; expected #{expected_range}"
          raise message
        end
      end
    end
  end
end