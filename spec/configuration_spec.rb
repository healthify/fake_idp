require "spec_helper"
require_relative "../lib/fake_idp/configuration"

describe FakeIdp::Configuration do
  it 'defaults encryption_enabled to false' do
    expect(subject.encryption_enabled).to be_falsey
  end

  context 'when ENCRYPTION_ENABLED is set' do
    before { ENV['ENCRYPTION_ENABLED'] = 'some_value' }
    it 'sets encryption_enabled to true' do
      expect(subject.encryption_enabled).to be_truthy
    end
    after { ENV.delete('ENCRYPTION_ENABLED') }
  end

  context 'when ENCRYPTION_ENABLED is implicitly disabled' do
    [nil, ''].each do |encryption_off|
      before { ENV['ENCRYPTION_ENABLED'] = encryption_off }

      it 'sets encryption_enabled to false' do
        expect(subject.encryption_enabled).to be_falsey
      end
      after { ENV.delete('ENCRYPTION_ENABLED') }
    end
  end
end