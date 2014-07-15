require "cucumber/rest/caching"

shared_examples "a cache header inspector" do |method, *header_names|

  ["Cache-Control", "Date", "Expires"].each do |header_name|
    it "raises an error when the #{header_name} header is missing" do
      response = generate_response
      response[header_name] = nil
      expect {
        Cucumber::Rest::Caching.send(method, { response: response })
      }.to raise_error "Required header '#{header_name}' is missing"
    end
  end

end

describe Cucumber::Rest::Caching, :caching do

  context "#ensure_response_is_publicly_cacheable" do

    def generate_response(duration = 3600, date = DateTime.now, age = nil)
      response = MockResponse.new
      response["Cache-Control"] = "public, max-age=#{duration}"
      response["Expires"] = (date + (duration / (24.0 * 3600))).strftime(RFC822_DATE_FORMAT)
      if age
        date += age / 86400.0
        response["Age"] = age.to_s if age
      end
      response["Date"] = date.strftime(RFC822_DATE_FORMAT)
      response.body = "test"
      response
    end

    context "with cacheable responses" do
      it_behaves_like "a cache header inspector", :ensure_response_is_publicly_cacheable

      it "does not raise an error when the public cache headers are set correctly" do
        duration = 3600
        response = generate_response(duration)
        Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response, duration: duration)
      end      

      it "does not raise an error when the public cache headers are set correctly, including an Age header" do
        duration = 3600
        response = generate_response(duration, DateTime.now, 243)
        Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response, duration: duration)
      end

      ["max-age"].each do |directive| # TODO: Should include "public" 
        it "raises an error when the Cache-Control header does not include the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] = response["Cache-Control"].split(/\s*,\s*/).reject { |d| d =~ /^#{directive}($|=)/ }.join(", ")
          expect {
            Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response)
          }.to raise_error "Cache-Control should include the '#{directive}' directive"
        end
      end

      ["private", "no-cache", "no-store"].each do |directive|     
        it "raises an error when the Cache-Control header includes the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] << ", #{directive}"
          expect {
            Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response)
          }.to raise_error "Cache-Control should not include the '#{directive}' directive"
        end
      end

      it "raises an error when Date, Expires and Cache-Control:max-age are inconsistent" do
        response = generate_response
        response["Expires"] = DateTime.now.strftime(RFC822_DATE_FORMAT)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response)
        }.to raise_error "Age, Date, Expires and Cache-Control:max-age are inconsistent"
      end

      it "raises an error when Age, Date, Expires and Cache-Control:max-age are inconsistent" do
        response = generate_response
        response["Age"] = "5"
        expect {
          Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response)
        }.to raise_error "Age, Date, Expires and Cache-Control:max-age are inconsistent"
      end

      it "raises an error when the Pragma header includes the no-cache directive" do
        response = generate_response
        response["Pragma"] = "no-cache"
        expect {
          Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response)
        }.to raise_error "Pragma should not include the 'no-cache' directive"
      end

    end

    context "with application-level requirements" do

      it "raises an error when the cache duration is higher than the expected duration" do
        response = generate_response(3600)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 3600s but expected no more than 1800s"
      end

      it "raises an error when the cache duration is lower than the expected duration" do
        response = generate_response(900)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 900s but expected at least 1800s"
      end

    end

  end

  context "#ensure_response_is_privately_cacheable" do

    def generate_response(duration = 3600, date = DateTime.now)
      response = MockResponse.new
      response["Cache-Control"] = "private, max-age=#{duration}"
      response["Date"] = date.strftime(RFC822_DATE_FORMAT)
      response["Expires"] = date.strftime(RFC822_DATE_FORMAT)
      response.body = "test"
      response
    end

    context "with non-cacheable responses" do
      it_behaves_like "a cache header inspector", :ensure_response_is_privately_cacheable

      it "does not raise an error when the private cache headers are set correctly" do
        duration = 3600
        response = generate_response(duration)
        Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response, duration: duration)
      end

      it "does not raise an error when the private cache headers are set correctly, with Expires as -1" do
        duration = 3600
        response = generate_response(duration)
        response["Expires"] = "-1" # invalid, but should be treated as in the past (i.e. already expired)
        Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response, duration: duration)
      end

      ["private", "max-age"].each do |directive|     
        it "raises an error when the Cache-Control header does not include the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] = response["Cache-Control"].split(/\s*,\s*/).reject { |d| d =~ /^#{directive}($|=)/ }.join(", ")
          expect {
            Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response)
          }.to raise_error "Cache-Control should include the '#{directive}' directive"
        end
      end

      ["public", "no-cache", "no-store"].each do |directive|     
        it "raises an error when the Cache-Control header includes the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] << ", #{directive}"
          expect {
            Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response)
          }.to raise_error "Cache-Control should not include the '#{directive}' directive"
        end
      end

      it "raises an error when Expires is a valid date later than Date" do
        response = generate_response
        response["Expires"] = (DateTime.now + 10).strftime(RFC822_DATE_FORMAT)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response)
        }.to raise_error "Expires should not be later than Date"
      end

      it "raises an error when the Pragma header includes the no-cache directive" do
        response = generate_response
        response["Pragma"] = "no-cache"
        expect {
          Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response)
        }.to raise_error "Pragma should not include the 'no-cache' directive"
      end

    end

    context "with application-level requirements" do

      it "raises an error when the cache duration is higher than the expected duration" do
        response = generate_response(3600)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 3600s but expected no more than 1800s"
      end

      it "raises an error when the cache duration is lower than the expected duration" do
        response = generate_response(900)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_privately_cacheable(response: response, duration: 1800)
        }.to raise_error "Cache duration is 900s but expected at least 1800s"
      end

    end

  end

  context "#ensure_response_is_not_cacheable" do

    def generate_response(date = DateTime.now)
      response = MockResponse.new
      response["Cache-Control"] = "no-store"
      response["Date"] = date.strftime(RFC822_DATE_FORMAT)
      response["Expires"] = date.strftime(RFC822_DATE_FORMAT)
      response["Pragma"] = "no-cache"
      response.body = "test"
      response
    end

    context "with non-cacheable responses" do
      it_behaves_like "a cache header inspector", :ensure_response_is_not_cacheable

      it "does not raise an error when the prevent cache headers are set correctly" do
        Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: generate_response)
      end

      it "does not raise an error when the public cache headers are set correctly, with Expires as -1" do
        response = generate_response
        response["Expires"] = "-1" # invalid, but should be treated as in the past (i.e. already expired)
        Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: response)
      end

      ["no-store"].each do |directive|     
        it "raises an error when the Cache-Control header does not include the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] = response["Cache-Control"].split(/\s*,\s*/).reject { |d| d =~ /^#{directive}($|=)/ }.join(", ")
          expect {
            Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: response)
          }.to raise_error "Cache-Control should include the '#{directive}' directive"
        end
      end

      ["public", "private", "max-age"].each do |directive|     
        it "raises an error when the Cache-Control header includes the #{directive} directive" do
          response = generate_response
          response["Cache-Control"] << ", #{directive}"
          expect {
            Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: response)
          }.to raise_error "Cache-Control should not include the '#{directive}' directive"
        end
      end

      it "raises an error when Expires is a valid date later than Date" do
        response = generate_response
        response["Expires"] = (DateTime.now + 10).strftime(RFC822_DATE_FORMAT)
        expect {
          Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: response)
        }.to raise_error "Expires should not be later than Date"
      end

      it "raises an error when the Pragma header does not include the no-cache directive" do
        response = generate_response
        response["Pragma"] = nil
        expect {
          Cucumber::Rest::Caching.ensure_response_is_not_cacheable(response: response)
        }.to raise_error "Pragma should include the 'no-cache' directive"
      end

    end

  end

	context "#parse_httpdate" do

		it "doesn't raise an error when an RFC822 date is passed" do
			date = DateTime.now.strftime(RFC822_DATE_FORMAT)
			Cucumber::Rest::Caching.parse_httpdate(date)
		end

		it "doesn't raise an error when an ANCI C asctime format date is passed" do
			date = DateTime.now.strftime(ANSI_C_DATE_FORMAT)
			Cucumber::Rest::Caching.parse_httpdate(date)
		end

		it "doesn't raise an error when an RFC850 date is passed" do
			date = DateTime.now.strftime(RFC850_DATE_FORMAT)
			Cucumber::Rest::Caching.parse_httpdate(date)
		end

		it "raises an error when a non-English date is passed" do
			date = "ma, 14 heinä 2014 16:08:33 GMT"
			expect {
				Cucumber::Rest::Caching.parse_httpdate(date)
			}.to raise_error("invalid date")
		end

		it "raises an error when a non-GMT date is passed" do
			date = "Mon, 14 Jul 2014 16:33:04 +0100"
			expect {
				Cucumber::Rest::Caching.parse_httpdate(date)
			}.to raise_error("invalid date")
		end

		it "raises an error when empty date values are passed" do
			expect {
				Cucumber::Rest::Caching.parse_httpdate("")
			}.to raise_error("Empty date value")
		end

		it "handles having nil values being passed as being empty" do
			expect {
				Cucumber::Rest::Caching.parse_httpdate(nil)
			}.to raise_error("Empty date value")
		end

	end

end
