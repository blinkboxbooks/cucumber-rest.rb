require "active_support/core_ext/numeric/time"
require "cucumber/rest/caching"

Then(/^(?:the response|it)? is publicly cacheable$/) do
  Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable
end

Then(/^(?:the response|it)? is publicly cacheable for (a|\d+(?:\.\d+)?) (week|day|hour|minute|second)s?$/) do |num, unit|
  num = num == "a" ? 1 : num.to_f
  duration = num.send(unit.to_sym).to_i
  Cucumber::Rest::Caching.ensure_response_is_publicly_cacheable(duration: duration)
end

Then(/^(?:the response|it)? is privately cacheable$/) do
  Cucumber::Rest::Caching.ensure_response_is_privately_cacheable
end

Then(/^(?:the response|it)? is not cacheable$/) do
  Cucumber::Rest::Caching.ensure_response_is_not_cacheable
end