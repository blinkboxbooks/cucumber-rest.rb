require "cucumber/rest/body"

describe Cucumber::Rest::Body, :body do
  context "#ensure_empty" do
    def generate_response(body: nil)
      response = MockResponse.new
      response.body = body
      response
    end

    it "does not raise an error when the response body is empty" do
      response = generate_response(body: nil)
      expect { Cucumber::Rest::Body.ensure_empty(response: response) }.to_not raise_error
    end

    it "raises an error when the response body is non-empty" do
      response = generate_response(body: "something")
      expect { Cucumber::Rest::Body.ensure_empty(response: response) }.to raise_error
    end
  end
end
