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
      :idp_certificate,
      :idp_secret_key,
      :algorithm,
      :additional_attributes,
    )

    def initialize
      @callback_url = ENV['CALLBACK_URL']
      @sso_uid = ENV['SSO_UID']
      @username = ENV['USERNAME']
      @first_name = ENV['FIRST_NAME']
      @last_name = ENV['LAST_NAME']
      @email = ENV['EMAIL']
      @name_id = ENV['NAME_ID']
      @idp_certificate = default_idp_certificate
      @idp_secret_key = default_idp_secret_key
      @algorithm = default_algorithm
      @additional_attributes = {}
    end

    private

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
  end
end
