require_relative "encryptor"

module FakeIdp
  class Application < Sinatra::Base
    include SamlIdp::Controller

    get '/saml/auth' do
      begin
        decode_SAMLRequest(mock_saml_request)
        @saml_acs_url = callback_url

        configure_cert_and_keys

        @saml_response = encode_SAMLResponse(
            name_id,
            attributes_provider: attributes_statement(user_attrs),
        )

        erb :auth
      rescue => e
        puts e
      end
    end

    private

    def configuration
      FakeIdp.configuration
    end

    def callback_url
      configuration.callback_url
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

    def mock_saml_request
      current_gem_dir = File.dirname(__FILE__)
      sample_file_name = "#{current_gem_dir}/sample_init_request.txt"
      File.write(sample_file_name, params[:SAMLRequest]) if params[:SAMLRequest]
      File.read(sample_file_name).strip
    end

    def attributes_statement(attributes)
      attributes_xml = attributes_xml(attributes).join

      %[<saml:AttributeStatement>#{attributes_xml}</saml:AttributeStatement>]
    end

    def attributes_xml(attributes)
      attributes.map do |name, value|
        attribute_value = %[<saml:AttributeValue>#{value}</saml:AttributeValue>]

        %[<saml:Attribute Name="#{name}">#{attribute_value}</saml:Attribute>]
      end
    end
  end
end
