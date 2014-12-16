# Change log

## 0.1.9 ([#26](https://git.mobcastdev.com/TEST/cucumber-rest/pull/26) 2014-12-16 11:09:35)

Add a step for checking we specifically return a HTTP 202

Patch

 * Adds a step def for checking HTTP 202 responses

## 0.1.8 ([#25](https://git.mobcastdev.com/TEST/cucumber-rest/pull/25) 2014-12-10 16:31:08)

Http 204 status codes

Patch

Add support for handling HTTP 204 responses, checking that the body is empty.

Also whitespace changes because hard tabs are bad, mmkay?

## 0.1.7 ([#24](https://git.mobcastdev.com/TEST/cucumber-rest/pull/24) 2014-12-08 16:47:02)

Using `ensure_status` instead of `ensure_status_class`

A patch to fix checking the status with the correct method.

## 0.1.6 ([#23](https://git.mobcastdev.com/TEST/cucumber-rest/pull/23) 2014-12-08 16:18:09)

Made the item specified that is being create non capturing

A patch to make the user specified resource being created in the step's regex non-capturing.

## 0.1.5 ([#22](https://git.mobcastdev.com/TEST/cucumber-rest/pull/22) 2014-12-01 14:58:07)

adding step for checking 201 Created response

patch: adding step for checking 201 Created response

## 0.1.4 ([#21](https://git.mobcastdev.com/TEST/cucumber-rest/pull/21) 2014-10-14 16:38:44)

RSpec 3

### Improvements

- Move to RSpec 3

## 0.1.3 ([#20](https://git.mobcastdev.com/TEST/cucumber-rest/pull/20) 2014-10-13 10:21:36)

Fix where the version file is read from

Patch

VERSION file location was misdefined as one level too deep. If the VERSION file can't be found in the right folder, default to a more sane "0.0.0".

## 0.1.2 ([#19](https://git.mobcastdev.com/TEST/cucumber-rest/pull/19) 2014-10-09 17:28:41)

410 Gone step

Patch

## 0.1.1 ([#18](https://git.mobcastdev.com/TEST/cucumber-rest/pull/18) 2014-07-15 10:52:31)

CP-1598 - Make Cucumber-Rest stricter about what it considers a valid Date in HTTP headers

Patch to make Cucumber-Rest fall back to using DateTime.httpdate as opposed to generic Date parsing; such that it's more in keeping with the HTTP RFCs

## 0.1.0 ([#17](https://git.mobcastdev.com/TEST/cucumber-rest/pull/17) 2014-06-30 17:42:16)

Moved to artifactory

### New Features

- Moved to Artifactory
- Moved to using VERSION file.

