require 'rubygems'
require "active_record"
require "yaml"

RAILS_ENV = "test"
config_file = File.join(File.dirname(__FILE__), "database.yml")
config = YAML.load_file(config_file)
ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection(config[RAILS_ENV])
require File.join(File.dirname(__FILE__), "../init")
load File.join(File.dirname(__FILE__), "schema.rb")
