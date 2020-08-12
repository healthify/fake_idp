require "spec_helper"
require_relative "../lib/fake_idp/configuration"

describe FakeIdp::Configuration do
  it 'defaults encryption_enabled to false' do
    expect(subject.encryption_enabled).to be_falsey
  end

  context 'when ENCRYPTION_ENABLED is set' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ENCRYPTION_ENABLED").and_return("true")
    end

    it 'sets encryption_enabled to true' do
      expect(subject.encryption_enabled).to be_truthy
    end
  end

  context 'when ENCRYPTION_ENABLED is implicitly disabled' do
    [nil, '', 'false'].each do |encryption_off|
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ENCRYPTION_ENABLED").and_return(encryption_off)
      end

      it 'sets encryption_enabled to false' do
        expect(subject.encryption_enabled).to be_falsey
      end
    end
  end
end
