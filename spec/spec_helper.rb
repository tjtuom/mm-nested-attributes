require 'rubygems'
require 'rspec'
require 'mongo_mapper'

require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib mm-nested-attributes]))

Rspec.configure do |c|
  def Doc(name=nil, &block)
    klass = Class.new do
      include MongoMapper::Document
      set_collection_name :test

      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
    end

    klass.class_eval(&block) if block_given?
    klass.collection.remove
    klass
  end

  def EDoc(name=nil, &block)
    klass = Class.new do
      include MongoMapper::EmbeddedDocument

      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
    end

    klass.class_eval(&block) if block_given?
    klass
  end

  def doing(&block)
    block
  end

  MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017)
  MongoMapper.database = "mm-nested-attributes-test-#{RUBY_VERSION.gsub('.', '-')}"
  MongoMapper.database.collections.each { |c| c.drop_indexes }
end