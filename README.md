# Fake IdP

## Installation

Clone the repo and `cd` into the project directory.

    bundle install

## Running in Development

To run locally, you first need to set up the following environment variables:

    CALLBACK_URL (the URL of the Healthify app to POST to for SAML authentication)
    SSO_UID     (unique id of the user you want to log in as)
    USERNAME     (username of the user you want to log in as)

The `.env.example` file has examples of what these env variables could look like.

Next, to start the server, you can run:

    bundle exec rackup

Then navigate to `http://localhost:9292/saml/auth` to begin making your SAML requests.

## Running in Test

If you are using this gem to provide a Fake IDP server in a test suite,
you can set the callback
