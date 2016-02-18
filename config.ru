$LOAD_PATH << File.expand_path("../lib", __FILE__)
require "fake_idp"

run FakeIdp::Application
