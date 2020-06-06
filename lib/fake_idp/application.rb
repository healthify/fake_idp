require_relative "./saml_response"
require "ruby-saml"

module FakeIdp
  class Application < Sinatra::Base
    include SamlIdp::Controller

    get '/saml/auth' do
      begin
        decode_SAMLRequest(generate_saml_request)
        configure_cert_and_keys
        @saml_response = Base64.encode64(build_xml_saml_response)
binding.pry
        erb :auth
      rescue => e
        puts e
      end
    end

    private

    def build_xml_saml_response
      FakeIdp::SamlResponse.new(
        name_id: configuration.name_id,
        issuer_uri: configuration.issuer,
        saml_acs_url: @saml_acs_url, # Defined in #decode_SAMLRequest in the ruby-saml-idp gem
        saml_request_id: @saml_request_id, # Defined in #decode_SAMLRequest in the ruby-saml-idp gem
        user_attributes: user_attributes,
        algorithm_name: configuration.algorithm,
        certificate: configuration.idp_certificate,
        secret_key: configuration.idp_secret_key,
        encryption_enabled: configuration.encryption_enabled,
      ).build
    end

    def user_attributes
      {
        uuid: configuration.sso_uid,
        username: configuration.username,
        first_name: configuration.first_name,
        last_name: configuration.last_name,
        email: configuration.email,
      }
    end

    def configuration
      FakeIdp.configuration
    end

    def configure_cert_and_keys
      self.x509_certificate = idp_certificate
      self.secret_key = configuration.idp_secret_key
      self.algorithm = configuration.algorithm
    end

    def certificate
      Base64.encode64(configuration.certificate).delete("\n")
    end

    def idp_certificate
      Base64.encode64(configuration.idp_certificate).delete("\n")
    end

    def user_attrs
      signed_in_user_attrs.merge(configuration.additional_attributes)
    end

    def signed_in_user_attrs
      {
        uuid: configuration.sso_uid,
        username: configuration.username,
        first_name: configuration.first_name,
        last_name: configuration.last_name,
        email: configuration.email
      }
    end

    def name_id
      configuration.name_id
    end

    def generate_saml_request
      auth_request = OneLogin::RubySaml::Authrequest.new
      auth_url = auth_request.create(saml_settings)
      CGI.unescape(auth_url.split("=").last)
    end

    def saml_settings
      OneLogin::RubySaml::Settings.new.tap do |setting|
        setting.assertion_consumer_service_url = configuration.callback_url
        setting.issuer = configuration.issuer
        setting.idp_sso_target_url = configuration.idp_sso_target_url
        setting.name_identifier_format = FakeIdp::SamlResponse::EMAIL_ADDRESS_FORMAT
      end
    end
  end
end
