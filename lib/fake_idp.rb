require 'sinatra/base'
require 'ruby-saml-idp'
require 'builder'
require 'zlib'
require 'tilt/erb'
require 'fake_idp/configuration'
require 'fake_idp/application'

module FakeIdp
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset!
    @configuration = nil
  end
end
