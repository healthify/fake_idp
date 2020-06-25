require "spec_helper"
require_relative "../lib/fake_idp/configuration"

describe FakeIdp::Configuration do
  it 'defaults encryption_enabled to true' do
    expect(subject.encryption_enabled).to be_truthy
  end

  context 'when ENCRYPTION_ENABLED is true' do
    before { ENV['ENCRYPTION_ENABLED'] = 'true' }
    it 'sets encryption_enabled to true' do
      expect(subject.encryption_enabled).to be_truthy
    end
  end

  context 'when ENCRYPTION_ENABLED is false' do
    before { ENV['ENCRYPTION_ENABLED'] = 'false' }
    it 'sets encryption_enabled to false' do
      expect(subject.encryption_enabled).to be_falsey
    end
  end


end