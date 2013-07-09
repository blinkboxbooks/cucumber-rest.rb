require "http_capture"

module Cucumber
  module Rest
    module Cacheability

      def self.ensure_response_is_publicly_cacheable(args = {})
        response, min_duration, max_duration = extract_args(args)
        ensure_cache_headers(response, false)

        cache_control = parse_cache_control(response["Cache-Control"])
        ensure_cache_directives(cache_control, "public", "max-age")
        prohibit_cache_directives(cache_control, "private", "no-cache", "no-store")
        
        date = DateTime.parse(response["Date"])
        expires = DateTime.parse(response["Expires"])
        max_age = cache_control["max-age"]
        raise "Date, Expires and Cache-Control:max-age are inconsistent" unless max_age == expires - date

        ensure_cache_duration(max_age, min_duration, max_duration)
      end

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

      # def ensure_response_is_not_cacheable(response = last_response)
      #   cache_control = parse_cache_control(response.header["Cache-Control"].first)
      #   require_cache_params(cache_control, "no-store")
      #   prohibit_cache_params(cache_control, "public", "private", "max-age", "no-cache", "must-revalidate", "proxy-revalidate")
        
      #   date, expires, last_modified = extract_dates(response)
      #   expires.should <= date, "Expires should not be later than Date"
      #   last_modified.should <= date, "Last-Modified should not be later than Date"

      #   response.header["Pragma"].should include("no-cache")
      # end

      private

      def self.extract_args(args)
        response = args[:response] || HttpCapture::RESPONSES.last
        min_duration = args[:min_duration] || args[:duration] 
        max_duration = args[:max_duration] || args[:duration]
        return response, min_duration, max_duration
      end

      def self.ensure_cache_headers(response, expect_pragma_nocache)
        ["Cache-Control", "Date", "Expires"].each { |h| raise "Required header '#{h}' is missing" if response[h].nil? }
        has_pragma_nocache = (response["Pragma"] =~ /\bno-cache\b/) != nil
        raise "Pragma should not include the 'no-cache' directive" unless has_pragma_nocache == expect_pragma_nocache
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