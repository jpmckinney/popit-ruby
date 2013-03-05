require 'rubygems'
require 'rspec'
require File.dirname(__FILE__) + '/../lib/popit'

def credentials_file
  File.expand_path(File.dirname(__FILE__) + '/spec_auth.yml')
end

def credentials?
  File.exist?(credentials_file)
end

def credentials
  if credentials?
    YAML.load_file(credentials_file)
  else
    {:instance_name => 'tttest'}
  end
end
