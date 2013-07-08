require "http_capture"

module Cucumber
  module Rest
    module Cacheability

      def self.ensure_response_is_publicly_cacheable(args = {})
        response = args[:response] || HttpCapture::RESPONSES.last
        min_duration = args[:min_duration] || args[:duration] 
        max_duration = args[:max_duration] || args[:duration]

        ["Cache-Control", "Date", "Expires"].each { |h| raise "Required header '#{h}' is missing" if response[h].nil? }

        cache_control = parse_cache_control(response["Cache-Control"])
        ["public", "max-age"].each do |directive|
          raise "Cache-Control should include the '#{directive}' directive" unless cache_control.has_key?(directive)
        end
        ["private", "no-cache", "no-store"].each do |directive|
          raise "Cache-Control should not include the '#{directive}' directive" if cache_control.has_key?(directive)
        end
        
        date = DateTime.parse(response["Date"])
        expires = DateTime.parse(response["Expires"])
        max_age = cache_control["max-age"]
        raise "Date, Expires and Cache-Control:max-age are inconsistent" unless max_age == expires - date

        raise "Pragma should not include the 'no-cache' directive" if response["Pragma"] =~ /\bno-cache\b/

        if min_duration && max_age < min_duration
          raise "Cache duration is #{max_age}s but expected at least #{min_duration}s"
        end
        if max_duration && max_age > max_duration
          raise "Cache duration is #{max_age}s but expected no more than #{max_duration}s"
        end
      end

      # def ensure_response_is_privately_cacheable(response = last_response)
      #   cache_control = parse_cache_control(response.header["Cache-Control"].first)
      #   require_cache_params(cache_control, "private", "max-age")
      #   prohibit_cache_params(cache_control, "public", "no-cache", "no-store", "must-revalidate", "proxy-revalidate")
      #   cache_control["max-age"].should > 0, "The Cache-Control:max-age param must be greater than zero"
        
      #   date, expires, last_modified = extract_dates(response)
      #   expires.should <= date, "Expires should not be later than Date"
      #   last_modified.should <= date, "Last-Modified should not be later than Date"

      #   response.header["Pragma"].count.should == 0
      # end

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

      def self.parse_cache_control(cache_control)
        cache_control.split(",").each_with_object({}) do |entry, hash|
          key, value = entry.split("=", 2).map(&:strip)
          hash[key] = value =~ /^\d+$/ ? value.to_i : value
        end
      end

      def self.require_cache_params(cache_control, *keys)
        keys.each { |key| raise "The Cache-Control header must include #{key}" if cache_control[key].nil? }
      end

      def self.prohibit_cache_params(cache_control, *keys)
        keys.each { |key| raise "The Cache-Control header must not include #{key}" unless cache_control[key].nil? }
      end

      def self.extract_dates(response)
        date = date_from_header(response, "Date")
        expires = date_from_header(response, "Expires")
        last_modified = date_from_header(response, "Last-Modified")
        return date, expires, last_modified
      end

      def self.date_from_header(response, name)
        Time.parse(response[name])
      end

    end
  end
end