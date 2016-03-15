module FakeIdp
  class Configuration
    attr_accessor :callback_url, :sso_uid, :username, :name_id
    def initialize
      @callback_url = ENV['CALLBACK_URL']
      @sso_uid = ENV['SSO_UID']
      @username = ENV['USERNAME']
      @name_id = ENV['NAME_ID']
    end
  end
end
