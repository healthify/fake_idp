# Fake IdP

## Installation

Clone the repo and `cd` into the project directory.

    bundle install

## Running in Development

To run locally, you first need to set up the following environment variables:

    CALLBACK_URL (the URL of the Healthify app to POST to for SAML authentication)
    SSO_UID      (unique id of the user you want to log in as)
    USERNAME     (username of the user you want to log in as)

The `.env.example` file has examples of what these env variables could look like.

Next, to start the server, you can run:

    bundle exec rackup

Then navigate to `http://localhost:9292/saml/auth` to begin making your SAML requests.

## Running in Test

If you are using this gem to provide a Fake IDP server in a test suite, add the gem
to the Gemfile:

    gem 'fake_idp', github: 'healthify/fake_idp'

you can set the relevant variables in a configuration block. For example:

    FakeIdp.configure do |config|
      config.callback_url = "http://localhost.dev:3000/auth/saml/devidp/callback"
      config.sso_uid = "12345"
    end

And then use Capybara Discoball to spin it up in a test:

    require 'fake_idp'

    before(:each) do
      FakeIdp.configure do |config|
        config.callback_url = consumer_url
        config.sso_uid = args.fetch(:user_data)[:uuid]
      end
    end

    it 'logs the sso user in' do
      Capybara::Discoball.spin(FakeIdp::Application) do |fake_idp_server|
        # ...
      end
    end

