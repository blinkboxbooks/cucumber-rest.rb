require "cucumber/rest/cacheability"

shared_examples "a cache header inspector" do |method, *header_names|

  ["Cache-Control", "Date", "Expires"].each do |header_name|
    it "raises an error when the #{header_name} header is missing" do
      response = cacheable_response
      response[header_name] = nil
      expect {
        Cucumber::Rest::Cacheability.send(method, { response: response })
      }.to raise_error "Required header '#{header_name}' is missing"
    end
  end

end

describe Cucumber::Rest::Cacheability, :cacheability do

  context "#ensure_response_is_publicly_cacheable" do

    def cacheable_response(duration = 3600, date = DateTime.now)
      response = HttpCapture::MockResponse.new
      response["Cache-Control"] = "public, max-age=#{duration}"
      response["Date"] = date.strftime(RFC822_DATE_FORMAT)
      response["Expires"] = (date + duration).strftime(RFC822_DATE_FORMAT)
      response.body = "test"
      response
    end

    context "with non-cacheable responses" do
      it_behaves_like "a cache header inspector", :ensure_response_is_publicly_cacheable

      it "does not raise an error when the public cache headers are set correctly" do
        duration = 3600
        response = cacheable_response(duration)
        Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response, duration: duration)
      end

      ["public", "max-age"].each do |directive|     
        it "raises an error when the Cache-Control header does not include the #{directive} directive" do
          response = cacheable_response
          response["Cache-Control"] = response["Cache-Control"].split(/\s*,\s*/).reject { |d| d =~ /^#{directive}($|=)/ }.join(", ")
          expect {
            Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response)
          }.to raise_error "Cache-Control should include the '#{directive}' directive"
        end
      end

      ["private", "no-cache", "no-store"].each do |directive|     
        it "raises an error when the Cache-Control header includes the #{directive} directive" do
          response = cacheable_response
          response["Cache-Control"] << ", #{directive}"
          expect {
            Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response)
          }.to raise_error "Cache-Control should not include the '#{directive}' directive"
        end
      end

      it "raises an error when Date, Expires and Cache-Control:max-age are inconsistent" do
        response = cacheable_response
        response["Expires"] = DateTime.now.strftime(RFC822_DATE_FORMAT)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response)
        }.to raise_error "Date, Expires and Cache-Control:max-age are inconsistent"
      end

      it "raises an error when the Pragma header includes the no-cache directive" do
        response = cacheable_response
        response["Pragma"] = "no-cache"
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response)
        }.to raise_error "Pragma should not include the 'no-cache' directive"
      end

    end

    context "with application-level requirements" do

      it "raises an error when the cache duration is higher than the expected duration" do
        response = cacheable_response(3600)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 3600s but expected no more than 1800s"
      end

      it "raises an error when the cache duration is lower than the expected duration" do
        response = cacheable_response(900)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_publicly_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 900s but expected at least 1800s"
      end

    end

  end

  context "#ensure_response_is_privately_cacheable" do

    def cacheable_response(duration = 3600, date = DateTime.now)
      response = HttpCapture::MockResponse.new
      response["Cache-Control"] = "private, max-age=#{duration}"
      response["Date"] = date.strftime(RFC822_DATE_FORMAT)
      response["Expires"] = date.strftime(RFC822_DATE_FORMAT)
      response.body = "test"
      response
    end

    context "with non-cacheable responses" do
      it_behaves_like "a cache header inspector", :ensure_response_is_privately_cacheable

      it "does not raise an error when the public cache headers are set correctly" do
        duration = 3600
        response = cacheable_response(duration)
        Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response, duration: duration)
      end

      it "does not raise an error when the public cache headers are set correctly, with Expires as -1" do
        duration = 3600
        response = cacheable_response(duration)
        response["Expires"] = "-1" # invalid, but should be treated as in the past (i.e. already expired)
        Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response, duration: duration)
      end

      ["private", "max-age"].each do |directive|     
        it "raises an error when the Cache-Control header does not include the #{directive} directive" do
          response = cacheable_response
          response["Cache-Control"] = response["Cache-Control"].split(/\s*,\s*/).reject { |d| d =~ /^#{directive}($|=)/ }.join(", ")
          expect {
            Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response)
          }.to raise_error "Cache-Control should include the '#{directive}' directive"
        end
      end

      ["public", "no-cache", "no-store"].each do |directive|     
        it "raises an error when the Cache-Control header includes the #{directive} directive" do
          response = cacheable_response
          response["Cache-Control"] << ", #{directive}"
          expect {
            Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response)
          }.to raise_error "Cache-Control should not include the '#{directive}' directive"
        end
      end

      it "raises an error when Expires is a valid date later than Date" do
        response = cacheable_response
        response["Expires"] = (DateTime.now + 10).strftime(RFC822_DATE_FORMAT)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response)
        }.to raise_error "Expires should not be later than Date"
      end

      it "raises an error when the Pragma header includes the no-cache directive" do
        response = cacheable_response
        response["Pragma"] = "no-cache"
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response)
        }.to raise_error "Pragma should not include the 'no-cache' directive"
      end

    end

    context "with application-level requirements" do

      it "raises an error when the cache duration is higher than the expected duration" do
        response = cacheable_response(3600)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 3600s but expected no more than 1800s"
      end

      it "raises an error when the cache duration is lower than the expected duration" do
        response = cacheable_response(900)
        expect {
          Cucumber::Rest::Cacheability.ensure_response_is_privately_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 900s but expected at least 1800s"
      end

    end

  end

end