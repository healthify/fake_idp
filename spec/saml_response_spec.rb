# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/fake_idp/saml_response"
require "ruby-saml"
require "securerandom"

RSpec.describe FakeIdp::SamlResponse do
  before do
    FakeIdp.configure do |config|
      config.callback_url = "http://localhost.dev:3000/auth/saml/devidp/callback"
      config.sso_uid = "12345"
      config.username = "bobthessouser"
      config.name_id = "bobthessouser@example.com"
      config.first_name = "Reid"
      config.last_name = "Smith"
      config.email = "reid@msn.com"
      config.idp_certificate = fake_public_certificate
      config.idp_secret_key = fake_private_key
      config.algorithm = :sha1
    end
  end

  let(:configuration) { FakeIdp.configuration }
  let(:settings) do
    OneLogin::RubySaml::Settings.new(
      allowed_clock_drift: 10_000_000,
      assertion_consumer_service_url: configuration.callback_url,
      idp_cert: configuration.idp_certificate,
      private_key: fake_private_key,
    )
  end

  context "encrypted assertion" do
    it "generates a valid SAML response" do
      saml_response = FakeIdp::SamlResponse.new(
        saml_acs_url: configuration.callback_url,
        saml_request_id: "_#{SecureRandom.uuid}",
        name_id: configuration.name_id,
        issuer_uri: "http://publichost.dev:3000",
        algorithm_name: configuration.algorithm,
        certificate: configuration.idp_certificate,
        secret_key: configuration.idp_secret_key,
        encryption_enabled: true,
        user_attributes: {
          uuid: configuration.sso_uid,
          username: configuration.username,
          first_name: configuration.first_name,
          last_name: configuration.last_name,
          email: configuration.email,
        },
      ).build

      response = OneLogin::RubySaml::Response.new(saml_response, settings: settings)
      response.is_valid?

      expect(response.errors).to be_empty
      expect(response.decrypted_document.to_s).to be_present
      expect(response.document.to_s).to be_present
    end
  end

  context "unencrypted assertion" do
    it "generates a valid SAML response without a decrypted document value" do
      saml_response = FakeIdp::SamlResponse.new(
        saml_acs_url: configuration.callback_url,
        saml_request_id: "_#{SecureRandom.uuid}",
        name_id: configuration.name_id,
        issuer_uri: "http://publichost.dev:3000",
        algorithm_name: configuration.algorithm,
        certificate: configuration.idp_certificate,
        secret_key: configuration.idp_secret_key,
        encryption_enabled: false,
        user_attributes: {
          uuid: configuration.sso_uid,
          username: configuration.username,
          first_name: configuration.first_name,
          last_name: configuration.last_name,
          email: configuration.email,
        },
      ).build

      response = OneLogin::RubySaml::Response.new(saml_response, settings: settings)
      response.is_valid?

      expect(response.errors).to be_empty
      expect(response.decrypted_document.to_s).to be_blank
      expect(response.document.to_s).to be_present
    end
  end

  def fake_public_certificate
    # Valid until Nov 27, 2119
    # SHA1
    # Generated at https://www.samltool.com/self_signed_certs.php
    <<~CERTIFICATE
      -----BEGIN CERTIFICATE-----
      MIICdjCCAd+gAwIBAgIBADANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJ1czER
      MA8GA1UECAwITmV3IFlvcmsxEjAQBgNVBAoMCUhlYWx0aGlmeTEhMB8GA1UEAwwY
      aHR0cHM6Ly93d3cuaGVhbHRoaWZ5LnVzMCAXDTE5MTEyNzE3NDEzOFoYDzIxMTkx
      MTAzMTc0MTM4WjBXMQswCQYDVQQGEwJ1czERMA8GA1UECAwITmV3IFlvcmsxEjAQ
      BgNVBAoMCUhlYWx0aGlmeTEhMB8GA1UEAwwYaHR0cHM6Ly93d3cuaGVhbHRoaWZ5
      LnVzMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCo36bWVM65irsOs/I6E8Wv
      52uOWQdxFuda62aKz/zwlx9KybFsuLfmZY3cEV48F/IPLBuT1Vp+i0I9SPWyyuYN
      dWJeERRF5NTx/PqCT3Es8WENvxLs/Rk/kdwe8FGg5h3yx5+o/FnGnQoFTmOPe0F8
      uiMFIICouw8Gj4Y5q2PnowIDAQABo1AwTjAdBgNVHQ4EFgQULd+auoipfMW3RspE
      6fN+M42cvYQwHwYDVR0jBBgwFoAULd+auoipfMW3RspE6fN+M42cvYQwDAYDVR0T
      BAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQCZH5XNLqS9k1qzqYiWjEihoO5pdSPF
      axKZi/fG3fg5RNjEVX6Xy/vpb3fXe/tbwi6lBeUOjvxd8gAwfz6JuKi7h5/67VtB
      Gd6ZpdPdVn5XO40EOYk9lapFvXMdeOaFUc9mxhl9N14v2QgMoQiFZTjEBvSAUO3M
      /KkasmgyucTmFQ==
      -----END CERTIFICATE-----
    CERTIFICATE
  end

  def fake_private_key
    # Valid until Nov 27, 2119
    # SHA1
    # Generated at https://www.samltool.com/self_signed_certs.php
    <<~CERTIFICATE
      -----BEGIN PRIVATE KEY-----
      MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAKjfptZUzrmKuw6z
      8joTxa/na45ZB3EW51rrZorP/PCXH0rJsWy4t+ZljdwRXjwX8g8sG5PVWn6LQj1I
      9bLK5g11Yl4RFEXk1PH8+oJPcSzxYQ2/Euz9GT+R3B7wUaDmHfLHn6j8WcadCgVO
      Y497QXy6IwUggKi7DwaPhjmrY+ejAgMBAAECgYB2xAwm0rAsp1fVCFMD62Hty1jG
      XPCx5UTCmamdWJdwcSgNxfmlF+gl/igdrI1UwBZ5+zBN8Q/azX/BcC10F+RgUEbz
      7buOsMuFn/Ge6NOw/jxaIc6ndxvDegNCV0fWU8Lah9KWX+USDXWJF37w48PJEJH3
      Z/sOka8g5UCDsj7mGQJBANA2TZo99QgSMVIkg0rp8uNzdHJ9Hm/f7A9CqgVYA8el
      o3tLlf8DEYrbnutBpXNZL+RsRcacn3LAa0jJr8mZ4V0CQQDPofq+TP2hWJHv36Z1
      ZHPm8Omj5K++YKnfxeqWN23PcYETs8+z9wCu8Miodc8FtbJNlccWphCN635gI6XJ
      q1z/AkEAu7bJfe6v08f7GVB74fVLmo5DhNiSsVATFasHd+vi9IK8AfOiVpegoCzi
      eLzlejoFOI341lfsVNtvnd7fkgUerQJBAIJz6u6VwOUWmNp1Ukh/jLKUurbWf/TF
      FvYZi4JF4SBs2ARg/Sa9EhjX/7qYCjI0LorAiA2a2NvSEdyliQxkNlECQQCcOnjL
      y7sYkKzqqsEqxERkqDrGdv0DJlNBA9rV+pkVuxzLILemOfsLs0ACYPp24ZEFMDDP
      bx1jtKkLjq8KYMzh
      -----END PRIVATE KEY-----
    CERTIFICATE
  end
end
