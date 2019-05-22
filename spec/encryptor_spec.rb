require "spec_helper"
require "builder"

describe FakeIdp::Encryptor do
  it "encrypts and decrypts XML" do
    raw_xml = "<foo>bar</foo>"
    encryptor = described_class.new(raw_xml, Base64.encode64(fake_certificate).delete("\n"))
    encrypted_xml = encryptor.encrypt

    expect(encrypted_xml).to_not match raw_xml

    encrypted_doc = Nokogiri::XML::Document.parse(encrypted_xml)
    encrypted_data = Xmlenc::EncryptedData.new(
      encrypted_doc.at_xpath("//xenc:EncryptedData", Xmlenc::NAMESPACES)
    )
    decrypted_xml = encrypted_data.decrypt(encryptor.encryption_key)

    expect(decrypted_xml).to eq(raw_xml)
  end

  def fake_certificate
    # Valid until May 22, 2069
    # SHA512
    # Generated at https://www.samltool.com/self_signed_certs.php
    <<~CERTIFICATE
      -----BEGIN CERTIFICATE-----
      MIICljCCAf+gAwIBAgIBADANBgkqhkiG9w0BAQ0FADBnMQswCQYDVQQGEwJ1czEL
      MAkGA1UECAwCTlkxGTAXBgNVBAoMEEhlYWx0aGlmeSBbVGVzdF0xHTAbBgNVBAMM
      FGh0dHBzOi8vaGVhbHRoaWZ5LnVzMREwDwYDVQQHDAhOZXcgWW9yazAgFw0xOTA1
      MjIxMzEyMzdaGA8yMDY5MDUwOTEzMTIzN1owZzELMAkGA1UEBhMCdXMxCzAJBgNV
      BAgMAk5ZMRkwFwYDVQQKDBBIZWFsdGhpZnkgW1Rlc3RdMR0wGwYDVQQDDBRodHRw
      czovL2hlYWx0aGlmeS51czERMA8GA1UEBwwITmV3IFlvcmswgZ8wDQYJKoZIhvcN
      AQEBBQADgY0AMIGJAoGBALc6dJ/o845WZC0pUGTqWyfVuS1L+FuELpTZC4Go47aC
      CARMiqD3kfwUEa88HMLO37bNs6+DB2qXmHD+qNsBD5BZJjZRMolU2ULz1kK7E3X2
      MqA9220ybFYrRuBL/S5WRKNpUYRL9owOSqN+wMWwrl7JiNoQMRGLMILGJ5P8jwhL
      AgMBAAGjUDBOMB0GA1UdDgQWBBRutCCXrlZZIs1sxQtku28fLnpU3TAfBgNVHSME
      GDAWgBRutCCXrlZZIs1sxQtku28fLnpU3TAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
      DQEBDQUAA4GBAET3DxmMTg9s42n4QTVTARPW1OyhPKMXE7ZA++yRTcdwY3gRaIyi
      nKbB6ZztCx1XqsZnJC/zKcTSZgcZ4uuG/TghDP+Ir9ZrmVcNkVoxTT2pEUcJVGGF
      DmAf2VRpbO/1vpG2kC0GmEryuFxJJg1wj8IxYCrT2N1yLTrRjg0S4HNJ
      -----END CERTIFICATE-----
    CERTIFICATE
  end
end
