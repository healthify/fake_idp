# Fake IdP

[![Build Status](https://travis-ci.com/healthify/fake_idp.svg?branch=main)](https://travis-ci.com/healthify/fake_idp)

## About

This is an open source Ruby gem intended for developers needing to spin up a fake Identity Provider (IdP) for testing SAML authentication flows. It's made by the [Healthify](http://healthify.us) team. It's _not_ for setting up an IdP within Healthify—to do that, you'll need to reach out to integrations@healthify.us.

## Installation

Clone the repo and `cd` into the project directory.

```sh
bin/setup
```

## Running in Development

To run locally, you first need to set up the following environment variables:

|Variables|Description|
|---|---|
|CALLBACK_URL|The URL of the Healthify app to POST to for SAML authentication - required|
|NAME_ID|Name_id of the user you want to log in as - may be nil/blank|
|SSO_UID|Unique id of the user you want to log in as - may be nil/blank|
|USERNAME|Username of the user you want to log in as - may be nil/blank|
|ENCRYPTION_ENABLED| Set to 'true' to indicate that the generated assertion should be encrypted. Defaults to false|

The `.env.example` file has examples of what these env variables could look like.
You can copy that over to your own `.env` file to set these environment variables:

    cp .env.example .env

Next, to start the server, you can run:

```sh
bin/server
```

Then navigate to `http://localhost:9292/saml/auth` to begin making your SAML requests.

## Running in Test

### Gemfile

If you are using this gem to provide a Fake IDP server in a test suite, add the gem to the Gemfile:

```ruby
group :test do
  gem 'fake_idp'
end
```

### Configuration

You can set the relevant variables in a configuration block if they aren't provided as environment variables. For example:

```ruby
FakeIdp.configure do |config|
  config.callback_url = 'http://localhost.dev:3000/auth/saml/devidp/callback'
  config.sso_uid = '12345'
  config.name_id = 'user@example.com'
  config.username = nil
  config.certificate = "YOUR CERT HERE"
  config.idp_certificate = "YOUR IDP CERT HERE"
  config.idp_secret_key = "YOUR IDP SECRET KEY HERE"
  config.algorithm = :sha512
  config.additional_attributes = { custom_saml_attr: "DELIVERED_IN_ASSERTION" }
end
```

#### Resetting Configuration

If you ever want to reset your FakeIdp configuration (e.g. between test specs), you can use the following:

```ruby
FakeIdp.reset!
```

### Use

You can use Capybara Discoball to spin `FakeIdp::Application` up in a test:

```ruby
require 'fake_idp'

before(:each) do
  FakeIdp.configure do |config|
    config.callback_url = callback_url
    config.sso_uid = sso_uid
    config.name_id = name_id
  end
end

it 'logs the sso user in' do
  Capybara::Discoball.spin(FakeIdp::Application) do |fake_idp_server|
    # ...
  end
end
```

### Generating a SAML Response

The gem provides a `SamlResponse` class used to generate a custom signed XML SAML response with an assertion that can be encrypted by setting `encryption_enabled` to `true`.

**Usage**

```ruby
# Instantiate with your IDP settings, user attributes and service provider details
saml_response = FakeIdp::SamlResponse.new(
  saml_acs_url: "http://localhost.dev:3000/auth/saml/devidp/callback",
  saml_request_id: "_#{SecureRandom.uuid}",
  name_id: "bob_builder@gmail.com",
  issuer_uri: "http://publichost.dev:3000",
  algorithm_name: :sha256,
  certificate: "YOUR IDP CERTIFICATE HERE",
  secret_key: "YOUR IDP SECRET KEY HERE",
  encryption_enabled: false,
  user_attributes: {
    uuid: "12345",
    username: "bob_builder",
    first_name: "Bob",
    last_name: "The Builder",
    email: "bob_builder@gmail.com",
  },
)

# Returns a signed XML SAML response document
saml_response.build
```
