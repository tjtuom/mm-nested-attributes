mm-nested-attributes
    by Toni Tuominen
    http://github.com/tjtuom/mm-nested-attributes

== DESCRIPTION:

A port of ActiveRecord's nested attributes functionality for MongoMapper.

== FEATURES/PROBLEMS:

At the moment only collection functionality is supported.

== SYNOPSIS:

class Parent
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Associations::NestedAttributes

  many :children
  accepts_nested_attributes_for :children
end

class Child
  include MongoMapper::Document

  key :foo, String
end

== REQUIREMENTS:

* MongoMapper

== INSTALL:

Add
gem 'mm-nested-attributes'
to your Gemfile.

== LICENSE:

(The MIT License)

Copyright (c) 2010

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
