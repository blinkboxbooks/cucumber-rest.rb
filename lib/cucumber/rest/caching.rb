require "date"
require "http_capture"

module Cucumber
  module Rest
    # Helper functions for checking the cacheability of responses.
    module Caching

      # Ensures that a response is privately cacheable.
      #
      # This function uses a strict interpretation of RFC 2616 to ensure the widest interoperability with 
      # implementations, including HTTP 1.0.
      #
      # @param response [HttpCapture::Response] The response to check. If not supplied defaults to the last response.
      # @param min_duration [Integer] The minimum permitted cache duration, in seconds.
      # @param max_duration [Integer] The maximum permitted cache duration, in seconds.
      # @param duration [Integer] The required cache duration, in seconds. Convenient if min and max are the same.
      # @return [nil]
      def self.ensure_response_is_publicly_cacheable(args = {})
        response, min_duration, max_duration = extract_args(args)
        ensure_cache_headers(response, false)

        cache_control = parse_cache_control(response["Cache-Control"])
        ensure_cache_directives(cache_control, "public", "max-age")
        prohibit_cache_directives(cache_control, "private", "no-cache", "no-store")
        
        age = response["Age"].to_i
        date = DateTime.parse(response["Date"])
        expires = DateTime.parse(response["Expires"])
        max_age = cache_control["max-age"]
        expected_max_age = age + ((expires - date) * 24 * 3600).to_i
        unless max_age >= expected_max_age - 1 && max_age <= expected_max_age + 1 # 1 second leeway
          raise "Age, Date, Expires and Cache-Control:max-age are inconsistent" 
        end

        ensure_cache_duration(max_age, min_duration, max_duration)
      end

      # Ensures that a response is privately cacheable.
      #
      # This function uses a strict interpretation of RFC 2616, including precedence rules for Date, Expires and
      # Cache-Control:max-age to ensure the widest interoperability with implementations, including HTTP 1.0.
      #
      # @param response [HttpCapture::Response] The response to check. If not supplied defaults to the last response.
      # @param min_duration [Integer] The minimum permitted cache duration, in seconds.
      # @param max_duration [Integer] The maximum permitted cache duration, in seconds.
      # @param duration [Integer] The required cache duration, in seconds. Convenient if min and max are the same.
      # @return [nil]
      def self.ensure_response_is_privately_cacheable(args = {})
        response, min_duration, max_duration = extract_args(args)
        ensure_cache_headers(response, false)

        cache_control = parse_cache_control(response["Cache-Control"])
        ensure_cache_directives(cache_control, "private", "max-age")
        prohibit_cache_directives(cache_control, "public", "no-cache", "no-store")
        
        date = DateTime.parse(response["Date"])
        expires = DateTime.parse(response["Expires"]) rescue nil # invalid values are treated as < now, which is fine
        raise "Expires should not be later than Date" if expires && expires > date

        ensure_cache_duration(cache_control["max-age"], min_duration, max_duration)
      end

      # Ensures that a response is not cacheable.
      #
      # This function uses a strict interpretation of RFC 2616, to ensure the widest interoperability with 
      # implementations, including HTTP 1.0.
      #
      # @param response [HttpCapture::Response] The response to check. If not supplied defaults to the last response.
      # @return [nil]
      def self.ensure_response_is_not_cacheable(args = {})
        response, * = extract_args(args)
        ensure_cache_headers(response, true)

        cache_control = parse_cache_control(response["Cache-Control"])
        ensure_cache_directives(cache_control, "no-store")
        prohibit_cache_directives(cache_control, "public", "private", "max-age") # TODO: prohibit no-cache?

        date = DateTime.parse(response["Date"])
        expires = DateTime.parse(response["Expires"]) rescue nil # invalid values are treated as < now, which is fine
        raise "Expires should not be later than Date" if expires && expires > date
      end

      private

      def self.extract_args(args)
        response = args[:response] || HttpCapture::RESPONSES.last
        if response.nil?
          raise "There is no response to check. Have you required the right capture file from HttpCapture?"
        end

        min_duration = args[:min_duration] || args[:duration] 
        max_duration = args[:max_duration] || args[:duration]
        
        return response, min_duration, max_duration
      end

      def self.ensure_cache_headers(response, pragma_nocache)
        ["Cache-Control", "Date", "Expires"].each { |h| raise "Required header '#{h}' is missing" if response[h].nil? }
        
        unless (/\bno-cache\b/ === response["Pragma"]) == pragma_nocache
          raise "Pragma should #{pragma_nocache ? "" : "not "}include the 'no-cache' directive" 
        end
      end

      def self.parse_cache_control(cache_control)
        cache_control.split(",").each_with_object({}) do |entry, hash|
          key, value = entry.split("=", 2).map(&:strip)
          hash[key] = value =~ /^\d+$/ ? value.to_i : value
        end
      end

      def self.ensure_cache_directives(cache_control, *directives)
        directives.each do |directive|
          raise "Cache-Control should include the '#{directive}' directive" unless cache_control.has_key?(directive)
        end
      end

      def self.prohibit_cache_directives(cache_control, *directives)
        directives.each do |directive|
          raise "Cache-Control should not include the '#{directive}' directive" if cache_control.has_key?(directive)
        end
      end

      def self.ensure_cache_duration(actual, min_expected, max_expected)
        if min_expected && actual < min_expected
          raise "Cache duration is #{actual}s but expected at least #{min_expected}s"
        end
        if max_expected && actual > max_expected
          raise "Cache duration is #{actual}s but expected no more than #{max_expected}s"
        end
      end

    end
  end
end