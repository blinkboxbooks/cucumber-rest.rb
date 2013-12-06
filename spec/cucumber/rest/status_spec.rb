require "cucumber/rest/status"

shared_examples "a status class inspector" do |status_class, min, max|
  def generate_response(status_code)
    response = MockResponse.new
    response.status = status_code
    response
  end

  Rack::Utils::HTTP_STATUS_CODES.keys.keep_if { |code| code >= min && code <= max }.each do |status_code|
    it "does not raise an error for status code #{status_code}" do
      Cucumber::Rest::Status.ensure_status_class(status_class, response: generate_response(status_code))
    end
  end
  Rack::Utils::HTTP_STATUS_CODES.keys.keep_if { |code| code < min || code > max }.each do |status_code|
    it "raises an error for status code #{status_code}" do
      expect {
        Cucumber::Rest::Status.ensure_status_class(status_class, response: generate_response(status_code))
        }.to raise_error
    end
  end
end

describe Cucumber::Rest::Status, :status do
  context "#ensure_status_class(:informational)" do
    it_behaves_like "a status class inspector", :informational, 100, 199
  end
  context "#ensure_status_class(:success)" do
    it_behaves_like "a status class inspector", :success, 200, 299
  end
  context "#ensure_status_class(:redirection)" do
    it_behaves_like "a status class inspector", :redirection, 300, 399
  end
  context "#ensure_status_class(:client_error)" do
    it_behaves_like "a status class inspector", :client_error, 400, 499
  end
  context "#ensure_status_class(:server_error)" do
    it_behaves_like "a status class inspector", :server_error, 500, 599
  end
end