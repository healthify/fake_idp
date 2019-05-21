require "xmlenc"

module FakeIdp
  class Application < Sinatra::Base
    include SamlIdp::Controller

    ENCRYPTION_STRATEGY = "aes256-cbc".freeze
    KEY_TRANSPORT = "rsa-oaep-mgf1p".freeze

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

    def callback_url
      FakeIdp.configuration.callback_url
    end

    def configure_cert_and_keys
      self.x509_certificate = idp_certificate
      self.secret_key = FakeIdp.configuration.idp_secret_key
      self.algorithm = FakeIdp.configuration.algorithm
    end

    def idp_certificate
      Base64.encode64(FakeIdp.configuration.idp_certificate).delete("\n")
    end

    def user_attrs
      signed_in_user_attrs.merge(FakeIdp.configuration.additional_attributes)
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
      encrypted_assertion_and_signature = encrypt(assertion_and_signature)

      xml = %[<samlp:Response ID="_#{response_id}" Version="2.0" IssueInstant="#{now.iso8601}" Destination="#{@saml_acs_url}" Consent="urn:oasis:names:tc:SAML:2.0:consent:unspecified"#{@saml_request_id ? %[ InResponseTo="#{@saml_request_id}"] : ""} xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer_uri}</saml:Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" /></samlp:Status>#{encrypted_assertion_and_signature}</samlp:Response>]

      Base64.encode64(xml)
    end

    # Encryption approach borrowed from
    # https://github.com/saml-idp/saml_idp/blob/master/lib/saml_idp/encryptor.rb
    def encrypt(raw_xml) 
      encryption_template = Nokogiri::XML::Document.parse(build_encryption_template).root
      encrypted_data = Xmlenc::EncryptedData.new(encryption_template)
      encryption_key = encrypted_data.encrypt(raw_xml)
      encrypted_key_node = encrypted_data.node.at_xpath(
        "//xenc:EncryptedData/ds:KeyInfo/xenc:EncryptedKey",
        Xmlenc::NAMESPACES
      )   
      encrypted_key = Xmlenc::EncryptedKey.new(encrypted_key_node)
      encrypted_key.encrypt(openssl_cert.public_key, encryption_key)

      xml = Builder::XmlMarkup.new
      xml.EncryptedAssertion xmlns: "urn:oasis:names:tc:SAML:2.0:assertion" do |enc_assert|
        enc_assert << encrypted_data.node.to_s
      end 
    end

    def openssl_cert
      if idp_certificate.is_a?(String)
        @_openssl_cert ||= OpenSSL::X509::Certificate.new(Base64.decode64(idp_certificate))
      else
        @_openssl_cert ||= idp_certificate
      end 
    end

    def encryption_strategy_ns
      "http://www.w3.org/2001/04/xmlenc##{ENCRYPTION_STRATEGY}"
    end

    def key_transport_ns
      "http://www.w3.org/2001/04/xmlenc##{KEY_TRANSPORT}"
    end

    def build_encryption_template
      xml = Builder::XmlMarkup.new
      xml.EncryptedData Id: "ED", Type: "http://www.w3.org/2001/04/xmlenc#Element",
        xmlns: "http://www.w3.org/2001/04/xmlenc#" do |enc_data|
        enc_data.EncryptionMethod Algorithm: encryption_strategy_ns
        enc_data.tag! "ds:KeyInfo", "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#" do |key_info|
          key_info.EncryptedKey Id: "EK", xmlns: "http://www.w3.org/2001/04/xmlenc#" do |enc_key|
            enc_key.EncryptionMethod Algorithm: key_transport_ns
            enc_key.tag! "ds:KeyInfo", "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#" do |key_info_child|
              key_info_child.tag! "ds:KeyName"
              key_info_child.tag! "ds:X509Data" do |x509_data|
                x509_data.tag! "ds:X509Certificate" do |x509_cert|
                  x509_cert << idp_certificate.to_s.gsub(/-+(BEGIN|END) CERTIFICATE-+/, "") 
                end
              end
            end

            enc_key.CipherData do |cipher_data|
              cipher_data.CipherValue
            end

            enc_key.ReferenceList do |ref_list|
              ref_list.DataReference URI: "#ED"
            end
          end
        end

        enc_data.CipherData do |cipher_data|
          cipher_data.CipherValue
        end
      end
    end
  end
end
