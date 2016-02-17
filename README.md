# Fake IdP

## Installation

Clone the repo and `cd` into the project directory.

    bundle install

Set the following environment variables (perhaps in your own `.env` file):

    CALLBACK_URL (the URL of the Healthify app to POST to for SAML authentication)
    SSO_UUID     (the UUID of the user you want to log in as)

The `.env.example` file has examples of what these env variables could look like.

## Running

To run locally, when you are inside the project root, simply run:

    bundle exec ruby app.rb

