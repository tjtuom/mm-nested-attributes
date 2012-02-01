# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mm-nested-attributes}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Toni Tuominen"]
  s.date = %q{2010-07-10}
  s.description = %q{A port of ActiveRecord's nested attributes functionality for MongoMapper.}
  s.email = %q{toni@piranhadigital.fi}
  s.extra_rdoc_files = ["History.txt", "README.txt", "version.txt"]
  s.files = [".gitignore", "History.txt", "README.txt", "Rakefile", "lib/mm-nested-attributes.rb", "lib/mongo_mapper/plugins/associations/nested_attributes.rb", "mm-nested-attributes.gemspec", "spec/mm-nested-attributes_spec.rb", "spec/rspec.opts", "spec/spec_helper.rb", "version.txt"]
  s.homepage = %q{http://github.com/tjtuom/mm-nested-attributes}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mm-nested-attributes}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A port of ActiveRecord's nested attributes functionality for MongoMapper}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongo_mapper>, [">= 0.8.2"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_development_dependency(%q<bones>, [">= 3.4.3"])
    else
      s.add_dependency(%q<mongo_mapper>, [">= 0.8.2"])
      s.add_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_dependency(%q<bones>, [">= 3.4.3"])
    end
  else
    s.add_dependency(%q<mongo_mapper>, [">= 0.8.2"])
    s.add_dependency(%q<rspec>, [">= 1.3.0"])
    s.add_dependency(%q<bones>, [">= 3.4.3"])
  end
end
