module FakeIdp
  class Configuration
    attr_accessor(
      :callback_url,
      :sso_uid,
      :username,
      :first_name,
      :last_name,
      :email,
      :name_id,
    )

    def initialize
      @callback_url = ENV['CALLBACK_URL']
      @sso_uid = ENV['SSO_UID']
      @username = ENV['USERNAME']
      @first_name = ENV['FIRST_NAME']
      @last_name = ENV['LAST_NAME']
      @email = ENV['EMAIL']
      @name_id = ENV['NAME_ID']
    end

    def x509_certificate
      SamlIdp::Default::X509_CERTIFICATE
    end

    def secret_key
      SamlIdp::Default::SECRET_KEY
    end
  end
end
