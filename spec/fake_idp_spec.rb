require "spec_helper"

describe FakeIdp do
  describe ".configure" do
    context 'valid configuration' do
      before do
        FakeIdp.configure do |config|
          config.callback_url = 'http://localhost.dev:3000/auth/saml/devidp/callback'
          config.sso_uid = '12345'
          config.username = 'bobthessouser'
          config.name_id = 'bobthessouser@example.com'
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

      it "sets the name_id" do
        name_id = FakeIdp.configuration.name_id

        expect(name_id).to eq('bobthessouser@example.com')
      end

      it "sets the idp_certificate" do
        expect do
          FakeIdp.configure { |config| config.idp_certificate = "INVALID_CERT" }
        end.to change { FakeIdp.configuration.idp_certificate }.to("INVALID_CERT")
      end

      it "sets the idp_secret_key" do
        expect do
          FakeIdp.configure { |config| config.idp_secret_key = "INVALID KEY" }
        end.to change { FakeIdp.configuration.idp_secret_key }.to("INVALID KEY")
      end

      it "sets the algorithm" do
        expect do
          FakeIdp.configure { |config| config.algorithm = :sha512 }
        end.to change { FakeIdp.configuration.algorithm }.from(:sha1).to(:sha512)
      end

      it "sets the additional_attributes" do
        expect do
          FakeIdp.configure { |config| config.additional_attributes = { foo: "bar" } }
        end.to change { FakeIdp.configuration.additional_attributes }.from({}).to({ foo: "bar" })
      end
    end
  end

  describe ".reset!" do
    before do
      FakeIdp.configure do |config|
        config.callback_url = "http://localhost.dev:3000/auth/saml/devidp/callback"
        config.sso_uid = "12345"
        config.username = "bobthessouser"
        config.name_id = "bobthessouser@example.com"
        config.additional_attributes = { foo: "bar" }
      end

      FakeIdp.reset!
    end

    it "resets the callback_url" do
      expect(FakeIdp.configuration.callback_url).
        not_to eq("http://localhost.dev:3000/auth/saml/devidp/callback")
    end

    it "resets the sso_uid" do
      expect(FakeIdp.configuration.sso_uid).not_to eq("12345")
    end

    it "resets the username" do
      expect(FakeIdp.configuration.username).not_to eq("bobthessouser")
    end

    it "resets the name_id" do
      expect(FakeIdp.configuration.name_id).not_to eq("bobthessouser@example.com")
    end

    it "resets the additional_attributes" do
      expect(FakeIdp.configuration.additional_attributes).not_to eq({ foo: "bar" })
    end
  end
end
