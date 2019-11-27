# frozen_string_literal: true

require "securerandom"
require "nokogiri"
require "openssl"

module FakeIdp
  class SamlResponse
    ISSUER_VALUE = "urn:oasis:names:tc:SAML:2.0:assertion"
    STATUS_CODE_VALUE = "urn:oasis:names:tc:SAML:2.0:status:Success"
    ENTITY_FORMAT = "urn:oasis:names:SAML:2.0:nameid-format:entity"
    SIGNATURE_SCHEMA = "http://www.w3.org/2000/09/xmldsig#"
    CANONICAL_SCHEMA = "http://www.w3.org/2001/10/xml-exc-c14n#"
    ENVELOPE_SCHEMA = "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
    DSIG = "http://www.w3.org/2000/09/xmldsig#"
    EMAIL_ADDRESS_FORMAT = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    BEARER_FORMAT = "urn:oasis:names:tc:SAML:2.0:cm:bearer"
    FEDERATION_SOURCE = "urn:federation:authentication:windows"
    SAML_VERSION = "2.0"

    def initialize(
      name_id:,
      audience_uri:,
      issuer_uri:,
      saml_acs_url:,
      saml_request_id:,
      user_attributes:,
      algorithm_name:,
      certificate:,
      secret_key:
    )
      @name_id = name_id
      @audience_uri = audience_uri
      @issuer_uri = issuer_uri
      @saml_acs_url = saml_acs_url
      @saml_request_id = saml_request_id
      @user_attributes = user_attributes
      @algorithm_name = algorithm_name
      @certificate = certificate
      @secret_key = secret_key
      @builder = Nokogiri::XML::Builder.new
      @timestamp = Time.now
      @digest_value = ""
    end

    def build
      @builder[:samlp].Response(root_namespace_attributes) do |response|
        build_issuer_segment(response)
        build_status_segment(response)
        build_assertion_segment(response)
      end
      @builder.to_xml
      doc_digest = response_with_replaced_signatures(@builder.to_xml)
      populate_signature_value(doc_digest)
    end

    private

    def response_with_replaced_signatures(document)
      copied_doc = document.dup

      working_doc = Nokogiri::XML(document)

      signature_element = working_doc.at_xpath("//ds:Signature", "ds" => DSIG)
      signature_element.remove

      assertion_without_signature = working_doc.
        at_xpath("//*[@ID=$id]", nil, "id" => assertion_reference_response_id)
      canon_hashed_element = assertion_without_signature.canonicalize(1, nil)

      # Create Digest Value
      digest_value = Base64.encode64(OpenSSL::Digest::SHA1.digest(canon_hashed_element)).strip

      ## Append the working copy with the new digest value
      copied_doc = Nokogiri::XML(copied_doc)
      target_digest_node = copied_doc.at_xpath("//ds:DigestValue")

      # Replace digest node value
      target_digest_node.content = digest_value
      copied_doc.to_xml
    end

    def populate_signature_value(document)
      copied_doc = document.dup

      working_doc = Nokogiri::XML(document)

      signature_element = working_doc.at_xpath("//ds:Signature", "ds" => DSIG)
      signed_info_element = signature_element.at_xpath("./ds:SignedInfo", "ds" => DSIG)
      canon_string = signed_info_element.canonicalize(1)

      signature_value = sign(canon_string)
      copied_doc = Nokogiri::XML(copied_doc)
      target_signature_node = copied_doc.at_xpath("//ds:SignatureValue")
      target_signature_node.content = signature_value
      copied_doc.to_xml
    end

    def sign(data)
      key = OpenSSL::PKey::RSA.new(@secret_key)
      # TODO Replace the algorithm
      Base64.encode64(key.sign(OpenSSL::Digest::SHA1.new, data)).gsub(/\n/, "")
    end

    def build_issuer_segment(parent_attribute)
      parent_attribute[:saml].Issuer("xmlns:saml" => ISSUER_VALUE) do |issuer|
        issuer << @issuer_uri
      end
    end

    def build_status_segment(parent_attribute)
      parent_attribute[:samlp].Status do |status|
        status[:samlp].StatusCode("Value" => STATUS_CODE_VALUE)
      end
    end

    def build_assertion_segment(parent_attribute)
      parent_attribute[:saml].Assertion(assertion_namespace_attributes) do |assertion|
        assertion[:saml].Issuer("Format" => ENTITY_FORMAT) do |issuer|
          issuer << @issuer_uri
        end

        assertion[:ds].Signature("xmlns:ds" => SIGNATURE_SCHEMA) do |signature|
          signature[:ds].SignedInfo("xmlns:ds" => SIGNATURE_SCHEMA) do |signed_info|
            signed_info[:ds].CanonicalizationMethod("Algorithm" => CANONICAL_SCHEMA)
            signed_info[:ds].SignatureMethod("Algorithm" => "#{DSIG}#{@algorithm_name}")

            signed_info[:ds].Reference("URI" => reference_uri) do |reference|
              reference[:ds].Transforms do |transform|
                transform[:ds].Transform("Algorithm" => ENVELOPE_SCHEMA)
                transform[:ds].Transform("Algorithm" => CANONICAL_SCHEMA)
              end

              reference[:ds].DigestMethod("Algorithm" => "#{DSIG}#{@algorithm_name}")

              # The digest_value is set during the request in application.rb
              reference[:ds].DigestValue { |d| d << "" }
            end
          end

          # The signature_value is set during the request in application.rb
          signature[:ds].SignatureValue { |signature_value| signature_value << "" }
          signature.KeyInfo("xmlns" => SIGNATURE_SCHEMA) do |key_info|
            key_info[:ds].X509Data do |x509_data|
              x509_data[:ds].X509Certificate do |x509_certificate|
                x509_certificate << Base64.encode64(@certificate)
              end
            end
          end
        end

        assertion[:saml].Subject do |subject|
          subject[:saml].NameID("Format" => EMAIL_ADDRESS_FORMAT) do |name_id|
            name_id << @name_id
          end

          subject[:saml].SubjectConfirmation("Method" => BEARER_FORMAT) do |subject_confirmation|
            subject_confirmation[:saml].SubjectConfirmationData(subject_confirmation_data) { "" }
          end
        end

        assertion[:saml].Conditions(saml_conditions) do |conditions|
          conditions[:saml].AudienceRestriction do |restriction|
            restriction[:saml].Audience { |audience| audience << @issuer_uri }
          end
        end

        assertion[:saml].AttributeStatement do |attribute_statement|
          @user_attributes.map do |name, value|
            attribute_statement[:saml].Attribute("Name" => name) do |attribute|
              attribute[:saml].AttributeValue { |attribute_value| attribute_value << value }
            end
          end
        end

        assertion[:saml].AuthnStatement(authn_statement) do |statement|
          statement[:saml].AuthnContext do |authn_context|
            authn_context[:saml].AuthnContextClassRef do |context_class_ref|
              context_class_ref << FEDERATION_SOURCE
            end
          end
        end
      end
    end

    def reference_response_id
      @_reference_response_id ||= "_#{SecureRandom.uuid}"
    end

    def assertion_reference_response_id
      @assertion_reference_response_id ||= "_#{SecureRandom.uuid}"
    end

    def reference_uri
      "_#{assertion_reference_response_id}"
    end

    def root_namespace_attributes
      {
        "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
        "Consent" => "urn:oasis:names:tc:SAML:2.0:consent:unspecified",
        "Destination" => @saml_acs_url,
        "ID" => reference_response_id,
        "InResponseTo" => @saml_request_id,
        "IssueInstant" => @timestamp.strftime("%Y-%m-%dT%H:%M:%S"),
        "Version" => SAML_VERSION,
        "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#",
      }
    end

    def assertion_namespace_attributes
      {
        "xmlns:saml" => ISSUER_VALUE,
        "ID" => assertion_reference_response_id,
        "IssueInstant" => @timestamp.strftime("%Y-%m-%dT%H:%M:%S"),
        "Version" => SAML_VERSION,
      }
    end

    def subject_confirmation_data
      {
        "InResponseTo" => @saml_request_id,
        "NotOnOrAfter" => (@timestamp + 3 * 60).strftime("%Y-%m-%dT%H:%M:%S"),
        "Recipient" => @saml_acs_url,
      }
    end

    def saml_conditions
      {
        "NotBefore" => (@timestamp - 5).strftime("%Y-%m-%dT%H:%M:%S"),
        "NotOnOrAfter" => (@timestamp + 60 * 60).strftime("%Y-%m-%dT%H:%M:%S"),
      }
    end

    def authn_statement
      {
        "AuthnInstant" => @timestamp.strftime("%Y-%m-%dT%H:%M:%S"),
        "SessionIndex" => reference_response_id,
      }
    end
  end
end
