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

    # This method overrides its definition in the ruby-saml-idp gem
    def encode_SAMLResponse(nameID, opts = {})
      now = Time.now.utc
      response_id, reference_id = SecureRandom.uuid, SecureRandom.uuid
      audience_uri = opts[:audience_uri] || saml_acs_url[/^(.*?\/\/.*?\/)/, 1]
      issuer_uri = opts[:issuer_uri] || (defined?(request) && request.url) || "http://example.com"
      attributes_statement = attributes(opts[:attributes_provider], nameID)

      session_expiration = ""
      if expires_in
        session_expiration = %{ SessionNotOnOrAfter="#{(now + expires_in).iso8601}"}
      end

      assertion = %[<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_#{reference_id}" IssueInstant="#{now.iso8601}" Version="2.0"><saml:Issuer Format="urn:oasis:names:SAML:2.0:nameid-format:entity">#{issuer_uri}</saml:Issuer><saml:Subject><saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">#{nameID}</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><saml:SubjectConfirmationData#{@saml_request_id ? %[ InResponseTo="#{@saml_request_id}"] : ""} NotOnOrAfter="#{(now+3*60).iso8601}" Recipient="#{@saml_acs_url}"></saml:SubjectConfirmationData></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore="#{(now-5).iso8601}" NotOnOrAfter="#{(now+60*60).iso8601}"><saml:AudienceRestriction><saml:Audience>#{audience_uri}</saml:Audience></saml:AudienceRestriction></saml:Conditions>#{attributes_statement}<saml:AuthnStatement AuthnInstant="#{now.iso8601}" SessionIndex="_#{reference_id}"#{session_expiration}><saml:AuthnContext><saml:AuthnContextClassRef>urn:federation:authentication:windows</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement></saml:Assertion>]

      digest_value = Base64.encode64(algorithm.digest(assertion)).gsub(/\n/, "")

      signed_info = %[<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-#{algorithm_name}"></ds:SignatureMethod><ds:Reference URI="#_#{reference_id}"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig##{algorithm_name}"></ds:DigestMethod><ds:DigestValue>#{digest_value}</ds:DigestValue></ds:Reference></ds:SignedInfo>]

      signature_value = sign(signed_info).gsub(/\n/, "")

      signature = %[<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">#{signed_info}<ds:SignatureValue>#{signature_value}</ds:SignatureValue><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><ds:X509Data><ds:X509Certificate>#{self.x509_certificate}</ds:X509Certificate></ds:X509Data></KeyInfo></ds:Signature>]

      assertion_and_signature = assertion.sub(/Issuer\>\<saml:Subject/, "Issuer>#{signature}<saml:Subject")

      if configuration.encryption_enabled
        assertion_and_signature = Encryptor.new(assertion_and_signature, certificate).encrypt
      end

      xml = %[<samlp:Response ID="_#{response_id}" Version="2.0" IssueInstant="#{now.iso8601}" Destination="#{@saml_acs_url}" Consent="urn:oasis:names:tc:SAML:2.0:consent:unspecified"#{@saml_request_id ? %[ InResponseTo="#{@saml_request_id}"] : ""} xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer_uri}</saml:Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" /></samlp:Status>#{assertion_and_signature}</samlp:Response>]

      Base64.encode64(xml)
    end
  end
end
