# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{egor}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Semin Lee"]
  s.cert_chain = ["/Users/semin/.gem/gem-public_cert.pem"]
  s.date = %q{2008-12-09}
  s.default_executable = %q{egor}
  s.description = %q{egor: Esst GeneratOR, a program for calculating environment-specific substitution tables}
  s.email = ["seminlee@gmail.com"]
  s.executables = ["egor"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "website/index.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/egor", "config/website.yml", "config/website.yml.sample", "egor.gemspec", "lib/egor.rb", "lib/egor/cli.rb", "lib/enumerable_extensions.rb", "lib/environment.rb", "lib/environment_feature.rb", "lib/math_extensions.rb", "lib/narray_extensions.rb", "lib/nmatrix_extensions.rb", "script/console", "script/destroy", "script/generate", "script/txt2html", "test/test_egor.rb", "test/test_egor_cli.rb", "test/test_enumerable_extensions.rb", "test/test_environment_feature.rb", "test/test_helper.rb", "test/test_nmatrix_extensions.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.html.erb"]
  s.has_rdoc = true
  s.homepage = %q{http://egor.rubyforge.org}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{egor}
  s.rubygems_version = %q{1.3.1}
  s.signing_key = %q{/Users/semin/.gem/gem-private_key.pem}
  s.summary = %q{egor: Esst GeneratOR, a program for calculating environment-specific substitution tables}
  s.test_files = ["test/test_egor.rb", "test/test_egor_cli.rb", "test/test_enumerable_extensions.rb", "test/test_environment_feature.rb", "test/test_helper.rb", "test/test_nmatrix_extensions.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_runtime_dependency(%q<bio>, [">= 1.2.1"])
      s.add_runtime_dependency(%q<facets>, [">= 2.4.5"])
      s.add_runtime_dependency(%q<simple_memoize>, [">= 1.0.0"])
      s.add_development_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_dependency(%q<bio>, [">= 1.2.1"])
      s.add_dependency(%q<facets>, [">= 2.4.5"])
      s.add_dependency(%q<simple_memoize>, [">= 1.0.0"])
      s.add_dependency(%q<newgem>, [">= 1.1.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<narray>, [">= 0.5.9.5"])
    s.add_dependency(%q<bio>, [">= 1.2.1"])
    s.add_dependency(%q<facets>, [">= 2.4.5"])
    s.add_dependency(%q<simple_memoize>, [">= 1.0.0"])
    s.add_dependency(%q<newgem>, [">= 1.1.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
