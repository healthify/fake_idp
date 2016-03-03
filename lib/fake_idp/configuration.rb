module FakeIdp
  class Configuration
    attr_accessor :callback_url, :sso_uid, :username, :email
    def initialize
      @callback_url = ENV['CALLBACK_URL']
      @sso_uid = ENV['SSO_UID']
      @username = ENV['USERNAME']
      @email = ENV['EMAIL']
    end
  end
end
