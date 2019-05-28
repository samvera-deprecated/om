source "https://rubygems.org"

gemspec

group :development, :test do
  gem 'rcov', :platform => :mri_18
  gem 'simplecov', :platform => :mri_19
  gem 'simplecov-rcov', :platform => :mri_19
end

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
