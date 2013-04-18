# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "stark-rack"
  s.version = "1.0.0.20130418154356"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Evan Phoenix"]
  s.date = "2013-04-18"
  s.description = "FIX (describe your package)"
  s.email = ["evan@phx.io"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = [".autotest", ".gemtest", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/stark/rack.rb", "stark-rack.gemspec", "test/calc-opt.rb", "test/calc.thrift", "test/config.ru", "test/gen-rb/calc.rb", "test/gen-rb/calc_constants.rb", "test/gen-rb/calc_types.rb", "test/test_rack.rb"]
  s.homepage = "http://github.com/evanphx/stark-rack"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "stark-rack"
  s.rubygems_version = "1.8.24"
  s.summary = "FIX (describe your package)"
  s.test_files = ["test/test_rack.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<stark>, ["< 2.0.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.5"])
    else
      s.add_dependency(%q<stark>, ["< 2.0.0"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe>, ["~> 3.5"])
    end
  else
    s.add_dependency(%q<stark>, ["< 2.0.0"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe>, ["~> 3.5"])
  end
end
