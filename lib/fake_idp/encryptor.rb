require "xmlenc"

module FakeIdp
  class Encryptor
    ENCRYPTION_STRATEGY = "aes256-cbc".freeze
    KEY_TRANSPORT = "rsa-oaep-mgf1p".freeze

    def initialize(raw_xml, idp_certificate)
      @raw_xml = raw_xml
      @idp_certificate = idp_certificate
    end

    # Encryption approach borrowed from
    # https://github.com/saml-idp/saml_idp/blob/master/lib/saml_idp/encryptor.rb
    def encrypt
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

    private

    attr_reader :raw_xml, :idp_certificate

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
