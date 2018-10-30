module FakeIdp
  class Application < Sinatra::Base
    include SamlIdp::Controller

    get '/saml/auth' do
      begin
        decode_SAMLRequest(mock_saml_request)
        @saml_acs_url = callback_url

        configure_cert_and_key
        @saml_response = encode_SAMLResponse(
            name_id,
            attributes_provider: attributes_statement(signed_in_user_attrs)
        )

        erb :auth
      rescue => e
        puts e
      end
    end

    private

    def callback_url
      FakeIdp.configuration.callback_url
    end

    def configure_cert_and_key
      self.x509_certificate = Base64.encode64(FakeIdp.configuration.idp_certificate).delete("\n")
      self.secret_key = FakeIdp.configuration.idp_secret_key
      self.algorithm = FakeIdp.configuration.algorithm
    end

    def signed_in_user_attrs
      {
        uuid: FakeIdp.configuration.sso_uid,
        username: FakeIdp.configuration.username,
        first_name: FakeIdp.configuration.first_name,
        last_name: FakeIdp.configuration.last_name,
        email: FakeIdp.configuration.email
      }
    end

    def name_id
      FakeIdp.configuration.name_id
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
