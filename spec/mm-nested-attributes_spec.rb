require File.join(File.dirname(__FILE__), %w[spec_helper])

describe "Nested attributes plugin" do
  before do
    @klass = Doc('Parent') do
      plugin MongoMapper::Plugins::Associations::NestedAttributes
      key :body, String
    end

    @child_klass = Doc('Child') do
      key :value, String
    end

    @solo_klass = Doc('Solo') do
      key :value, String
    end

    @klass.many :children, :class => @child_klass
    @klass.one :solo, :class => @solo_klass
    @klass.accepts_nested_attributes_for :children, :solo

    @parent = @klass.new
  end

  it "responds to #<plural_association>_attributes=" do
    @parent.should respond_to(:children_attributes=)
  end

  it "responds to #<singular_association>_attributes=" do
    @parent.should respond_to(:solo_attributes=)
  end

  it "raises an error for undefined associations" do
    doing { @klass.accepts_nested_attributes_for :foo }.should(
      raise_error(ArgumentError, "No association found for name 'foo'. Has it been defined yet?"))
  end

  it 'rejects the document if _destroy flag is present' do
    @parent = @klass.new(:children_attributes => [ { :value => 'ok' }, { :value => 'not ok', :_destroy => '1' } ])
    @parent.children.size.should == 1
    @parent.children[0].value.should == 'ok'
  end
end

describe "Nested attributes plugin for collections" do
  before do
    @klass = Doc('Parent') do
      plugin MongoMapper::Plugins::Associations::NestedAttributes
      key :body, String
    end

    @child_klass = Doc('Child') do
      key :value, String
    end

    @klass.many :children, :class => @child_klass
    @klass.accepts_nested_attributes_for :children

    @parent = @klass.new
  end

  describe "assigning attributes" do
    it "creates the child model when given an array" do
      @parent.children_attributes = [ { :value => "foo" } ]
      @parent.children.size.should == 1
      @parent.children[0].value.should == "foo"
    end

    it "creates the child model when given a hash" do
      @parent.children_attributes = { 0 => { :value => "foo" } }
      @parent.children.size.should == 1
      @parent.children[0].value.should == "foo"
    end
  end

  describe "initializing a new model" do
    it "creates the child model when given an array" do
      @parent = @klass.new(:children_attributes => [ { :value => "foo"} ])
      @parent.children.size.should == 1
      @parent.children[0].value.should == "foo"
    end

    it "creates the child model when given a hash" do
      @parent = @klass.new(:children_attributes => { 0 => { :value => "foo" } })
      @parent.children.size.should == 1
      @parent.children[0].value.should == "foo"
    end
  end

  describe "Nested attributes plugin for one_to_one" do
    before do
      @klass = Doc('Parent') do
        plugin MongoMapper::Plugins::Associations::NestedAttributes
        key :body, String
      end

      @child_klass = Doc('Child') do
        key :value, String
      end


      @klass.many :children, :class => @child_klass
      @klass.accepts_nested_attributes_for :children

      @parent = @klass.new
    end

  end


  describe "editing an existing document" do
    before do
      @klass = Doc('Parent') do
        plugin MongoMapper::Plugins::Associations::NestedAttributes
        key :body, String
      end

      @child_klass = Doc('Child') do
        key :value, String
      end

      @solo_klass = Doc('Solo') do
        key :value, String
      end

      @klass.many :children, :class => @child_klass
      @klass.one :solo, :class => @solo_klass
      @klass.accepts_nested_attributes_for :children, :solo

      @parent = @klass.new
    end

    after do
      TestParent.all.each {|t| t.destroy}
      TestOne.all.each {|t| t.destroy}
      TestSolo.all.each {|t| t.destroy}
    end
    
    it "raises an error if the document isn't found" do
      @parent = @klass.new
      @child = @parent.children.create!(:value => 'foo')
      @solo = @parent.solo.create!(:value => 'solo_foo')
      id = BSON::ObjectId.new
      doing do
        @parent.children_attributes = [ { :id => id, :value => 'bar' } ]
      end.should raise_error(MongoMapper::DocumentNotFound, "Couldn't find Child with ID=#{id} for Parent with ID=#{@parent.id}")
    end

    it 'updates the collection document' do
      @parent = @klass.create!(:value => 'parent_value')
      @child = @klass.first.children.create!(:value => 'foo')
    
      @parent.children_attributes = [ { :id => @child.id, :value => 'bar' } ]
      @parent.children[0].value.should == 'bar'
    
      # has not been saved so the db should have the old value

      @klass.first.children[0].value.should == 'foo'
    
      @parent.save!
    
      # after save the db should have the new value
      @klass.first.children[0].value.should == 'bar'
      @klass.first.destroy
    end

    it 'updates the one to one document' do
      TestParent.all.each(&:destroy)
      tp = TestParent.create!(:name => 'tp',
        :test_children_attributes => [{:name => 'tc1'},{:name => 'tc2'}],
        :test_one_attributes => {:name => 'to'},
      :test_solo_attributes => {:name => 'ts'})
      #require 'ruby-debug';debugger


      tp.test_one.name.should == 'to'
      tp.test_one_attributes = {:id => tp.test_one.id, :name => 'one_bar' }
      tp.test_one.name.should == 'one_bar'

      tp.test_solo.name.should == 'ts'
      tp.test_solo_attributes = {:id => tp.test_solo.id, :name => 'solo_bar' }
      tp.test_solo.name.should == 'solo_bar'


      # has not been saved so the db should have the old name

      tp.save!
      tp.test_one.name.should == 'one_bar'
      tp.test_solo.name.should == 'solo_bar'

      # after save the db should have the new name
      TestParent.find(tp.id).test_one.name.should == 'one_bar'
      TestParent.find(tp.id).test_solo.name.should == 'solo_bar'
      TestParent.find(tp.id).destroy
    end
  end

  describe "deleting an existing document" do
    it 'does nothing unless :allow_destroy is true' do
      @klass.accepts_nested_attributes_for :children

      @parent = @klass.new
      @child = @parent.children.create!(:value => 'foo')

      @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]
      doing do
        @parent.save!
      end.should_not change(@parent.children, :size)
    end

    it 'deletes the document when _destroy is present' do
      @klass.accepts_nested_attributes_for :children, :allow_destroy => true

      @parent = @klass.new
      @child = @parent.children.create!(:value => 'foo')

      @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]

      doing do
        @parent.save!
      end.should change(@parent.children, :size).by(-1)
    end

    it "does not delete the document until save is called" do
      @klass.accepts_nested_attributes_for :children, :allow_destroy => true

      @parent = @klass.new
      @child = @parent.children.create!(:value => 'foo')

      doing do
        @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]
      end.should_not change(@parent.children, :size)
    end
  end

  describe "limit option" do
    it "raises an error if more docs are given than are allowed" do
      @klass.accepts_nested_attributes_for :children, :limit => 1

      doing do
        @parent = @klass.new(:children_attributes => [ { :value => 'foo' }, { :bar => 'bar'} ])
      end.should raise_error(MongoMapper::TooManyRecords, "Maximum 1 records are allowed. Got 2 records instead.")
    end
  end

  describe "reject_if option" do
    it 'rejects docs that the block returns true for' do
      @klass.accepts_nested_attributes_for :children, :reject_if => proc { |attrs| attrs['value'] == 'reject' }

      @parent = @klass.new(:children_attributes => [ { :value => 'ok' }, { :value => 'reject' } ])
      @parent.children.size.should == 1
      @parent.children[0].value.should == 'ok'
    end

    it 'rejects fully empty objects if the reject_if option is set to :all_blank' do
      @klass.accepts_nested_attributes_for :children, :reject_if => :all_blank

      @parent = @klass.new(:children_attributes => [ { :value => '' }, { :value => 'ok' } ])
      @parent.children.size.should == 1
      @parent.children[0].value.should == 'ok'
    end
  end
end

describe "Nested attributes plugin for embedded document" do
  before do
    @klass = Doc('Parent') do
      plugin MongoMapper::Plugins::Associations::NestedAttributes
      key :body, String
    end

    @child_klass = EDoc('Child') do
      key :value, String
    end

    @klass.many :children, :class => @child_klass
    @klass.accepts_nested_attributes_for :children

    @parent = @klass.new
  end

  describe "deleting an existing document" do
    it 'does nothing unless :allow_destroy is true' do
      @klass.accepts_nested_attributes_for :children

      @parent = @klass.new
      @child = @child_klass.new(:value => 'foo')
      @parent.children << @child

      @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]
      doing do
        @parent.save!
      end.should_not change(@parent.children, :size)
    end

    it 'deletes the document when _destroy is present' do
      @klass.accepts_nested_attributes_for :children, :allow_destroy => true

      @parent = @klass.new
      @child = @child_klass.new(:value => 'foo')
      @parent.children << @child

      @parent.children.size.should eql(1)
      @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]
      @parent.children.size.should eql(0)

      #      doing do
      #        @parent.save!
      #      end.should change(@parent.children, :size)
    end

    #    it "does not delete the document until save is called" do
    #      @klass.accepts_nested_attributes_for :children, :allow_destroy => true
    #
    #      @parent = @klass.new
    #      @child = @parent.children.create!(:value => 'foo')
    #
    #      doing do
    #        @parent.children_attributes = [ { :id => @child.id, :_destroy => '1' } ]
    #      end.should_not change(@parent.children, :size)
    #    end
  end
end
