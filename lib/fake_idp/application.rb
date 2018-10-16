module FakeIdp
  class Application < Sinatra::Base
    include SamlIdp::Controller

    get '/saml/auth' do
      begin
        decode_SAMLRequest(mock_saml_request)
        @saml_acs_url = callback_url

        self.x509_certificate = idp_certificate
        self.secret_key = idp_private_key
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

    def idp_certificate
      Base64.encode64(FakeIdp.configuration.idp_certificate) ||
        SamlIdp::Default::X509_CERTIFICATE
    end

    def idp_private_key
      FakeIdp.configuration.idp_private_key ||
        SamlIdp::Default::SECRET_KEY
    end

    def callback_url
      FakeIdp.configuration.callback_url
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
      builder = Builder::XmlMarkup.new
      builder.saml :AttributeStatement do
        attributes.map do |name, value|
          builder.saml :Attribute, Name: name do
            builder.saml :AttributeValue, value
          end
        end
      end
    end
  end
end
