$VERBOSE = nil
require 'rubygems'
require 'bson'
require 'mongo_mapper'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib mm-nested-attributes]))

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  def Doc(name=nil, &block)
    klass = Class.new do
      include MongoMapper::Document
      set_collection_name name.to_sym

      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
    end

    klass.class_eval(&block) if block_given?
    klass.collection.remove
    klass
  end

  def doing(&block)
    block
  end

  MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017)
  MongoMapper.database = "mm-nested-attributes-test-#{RUBY_VERSION.gsub('.', '-')}"
  MongoMapper.database.collections.each { |c| c.drop_indexes }
  MongoMapper.database.collections.each { |c| c.remove }

end

