require "spec_helper"

describe FakeIdp do
  describe "#configure" do
    before do
      FakeIdp.configure do |config|
        config.callback_url = 'http://localhost.dev:3000/auth/saml/devidp/callback'
        config.sso_uid = '12345'
        config.username = 'bobthessouser'
      end
    end

    it "sets the callback_url" do
      url = FakeIdp.configuration.callback_url

      expect(url).to eq('http://localhost.dev:3000/auth/saml/devidp/callback')
    end

    it "sets the sso_uid" do
      uid = FakeIdp.configuration.sso_uid

      expect(uid).to eq('12345')
    end

    it "sets the username" do
      username = FakeIdp.configuration.username

      expect(username).to eq('bobthessouser')
    end
  end
end
