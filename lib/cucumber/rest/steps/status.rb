require "cucumber/rest/status"

Then(/^the request (?:is|was) successful$/) do
  Cucumber::Rest::Status.ensure_status_class(:success)
end

Then(/^the request (?:is|was) successful and (?:a resource|.+) was created$/) do
  Cucumber::Rest::Status.ensure_status_class(201)
end

Then(/^(?:it|the request) fails because it (?:is|was) invalid$/) do
  Cucumber::Rest::Status.ensure_status(400)
end

Then(/^(?:it|the request) fails because (?:.+) (?:is|was|am|are) unauthori[sz]ed$/) do
  Cucumber::Rest::Status.ensure_status(401)
end

Then(/^(?:it|the request) fails because (?:.+) (?:is|was) forbidden$/) do
  Cucumber::Rest::Status.ensure_status(403)
end

Then(/^(?:it|the request) fails because the (?:.+) (?:is|was) not found$/) do
  Cucumber::Rest::Status.ensure_status(404)
end

Then(/^(?:it|the request) fails because there (?:is|was) a conflict(?: with .+)?$/) do
  Cucumber::Rest::Status.ensure_status(409)
end

Then(/^(?:it|the request) fails because the (?:.+) (?:is|was|has) gone$/) do
  Cucumber::Rest::Status.ensure_status(410)
end
