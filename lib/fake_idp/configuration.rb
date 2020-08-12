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
      :certificate,
      :idp_certificate,
      :idp_secret_key,
      :idp_sso_target_url,
      :issuer,
      :algorithm,
      :additional_attributes,
      :encryption_enabled,
    )

    def initialize
      @callback_url = ENV['CALLBACK_URL']
      @sso_uid = ENV['SSO_UID']
      @username = ENV['USERNAME']
      @first_name = ENV['FIRST_NAME']
      @last_name = ENV['LAST_NAME']
      @email = ENV['EMAIL']
      @name_id = ENV['NAME_ID']
      @certificate = default_certificate
      @idp_certificate = default_idp_certificate
      @idp_secret_key = default_idp_secret_key
      @idp_sso_target_url = idp_sso_target_url
      @issuer = issuer
      @algorithm = default_algorithm
      @additional_attributes = {}
      @encryption_enabled = default_encryption
    end

    private

    def default_certificate
      ENV["CERTIFICATE"] ||
        SamlIdp::Default::X509_CERTIFICATE
    end

    def default_idp_certificate
      ENV["IDP_CERTIFICATE"] ||
        SamlIdp::Default::X509_CERTIFICATE
    end

    def default_idp_secret_key
      ENV["IDP_SECRET_KEY"] ||
        SamlIdp::Default::SECRET_KEY
    end

    def default_algorithm
      ENV["ALGORITHM"]&.to_sym ||
        :sha1
    end

    def default_encryption
      ENV["ENCRYPTION_ENABLED"] == "true"
    end
  end
end
