# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ulla}
  s.version = "0.9.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Semin Lee"]
  s.date = %q{2009-08-09}
  s.default_executable = %q{ulla}
  s.description = %q{'ulla' is a program for calculating environment-specific substitution tables from user providing environmental class definitions and sequence alignments with the annotations of the environment classes.}
  s.email = ["seminlee@gmail.com"]
  s.executables = ["ulla"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "website/index.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/ulla", "config/website.yml", "config/website.yml.sample", "lib/math_extensions.rb", "lib/narray_extensions.rb", "lib/nmatrix_extensions.rb", "lib/string_extensions.rb", "lib/ulla.rb", "lib/ulla/cli.rb", "lib/ulla/environment.rb", "lib/ulla/environment_class_hash.rb", "lib/ulla/environment_feature.rb", "lib/ulla/environment_feature_array.rb", "lib/ulla/heatmap_array.rb", "script/console", "script/destroy", "script/generate", "script/txt2html", "test/test_helper.rb", "test/test_math_extensions.rb", "test/test_narray_extensions.rb", "test/test_nmatrix_extensions.rb", "test/test_string_extensions.rb", "test/test_ulla.rb", "test/ulla/test_cli.rb", "test/ulla/test_environment_class_hash.rb", "test/ulla/test_environment_feature.rb", "ulla.gemspec", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.html.erb"]
  s.homepage = %q{http://www-cryst.bioc.cam.ac.uk/ulla}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ulla}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{'ulla' is a program for calculating environment-specific substitution tables from user providing environmental class definitions and sequence alignments with the annotations of the environment classes.}
  s.test_files = ["test/test_math_extensions.rb", "test/test_narray_extensions.rb", "test/test_nmatrix_extensions.rb", "test/test_string_extensions.rb", "test/ulla/test_cli.rb", "test/ulla/test_environment_class_hash.rb", "test/ulla/test_environment_feature.rb", "test/test_helper.rb", "test/test_ulla.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_runtime_dependency(%q<bio>, [">= 1.2.1"])
      s.add_runtime_dependency(%q<facets>, [">= 2.4.5"])
      s.add_runtime_dependency(%q<rmagick>, [">= 2.9.1"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_dependency(%q<bio>, [">= 1.2.1"])
      s.add_dependency(%q<facets>, [">= 2.4.5"])
      s.add_dependency(%q<rmagick>, [">= 2.9.1"])
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<narray>, [">= 0.5.9.5"])
    s.add_dependency(%q<bio>, [">= 1.2.1"])
    s.add_dependency(%q<facets>, [">= 2.4.5"])
    s.add_dependency(%q<rmagick>, [">= 2.9.1"])
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end
