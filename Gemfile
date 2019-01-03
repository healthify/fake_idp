source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# overrides gem source in gemspec
# needed to enable attributes statement in SAMLRequest
gem 'ruby-saml-idp', github: 'lawrencepit/ruby-saml-idp'

gemspec
