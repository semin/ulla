# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ulla}
  s.version = "0.9.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Semin Lee"]
  s.date = %q{2009-02-23}
  s.default_executable = %q{ulla}
  s.description = %q{'ulla' is a program for calculating environment-specific substitution tables from user providing environmental class definitions and sequence alignments with the annotations of the environment classes.}
  s.email = ["seminlee@gmail.com"]
  s.executables = ["ulla"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "website/index.txt"]
  s.files = [".git/COMMIT_EDITMSG", ".git/HEAD", ".git/config", ".git/description", ".git/hooks/applypatch-msg.sample", ".git/hooks/commit-msg.sample", ".git/hooks/post-commit.sample", ".git/hooks/post-receive.sample", ".git/hooks/post-update.sample", ".git/hooks/pre-applypatch.sample", ".git/hooks/pre-commit.sample", ".git/hooks/pre-rebase.sample", ".git/hooks/prepare-commit-msg.sample", ".git/hooks/update.sample", ".git/index", ".git/info/exclude", ".git/logs/HEAD", ".git/logs/refs/heads/master", ".git/logs/refs/remotes/origin/HEAD", ".git/objects/06/9494e479f28b5751fb135b8e55e8fef3d3a02e", ".git/objects/22/0df784191ad94983ca1d943e49fe482c9d1069", ".git/objects/3b/b6f2b7f563175a13a0ccd723aab761552f448b", ".git/objects/41/f48aefb4d7a6a87eb423eaae77ae1e8a58dd6c", ".git/objects/44/d1f1782e3ea1d9fd2f9054784b53e8e810a8ca", ".git/objects/4f/364c2eac29f5c7fcbf06419c4f58074cd32ace", ".git/objects/57/1326145a7a4b3e58f3d3008ba343135f213b05", ".git/objects/6c/4f0844f62b7345f0651b0fb2829a8f157469fb", ".git/objects/73/8dc79450de050f12d48a32602f2ddbe6807029", ".git/objects/7b/4acb3aee6616d80e295ee21fe8bb7ee93ebe96", ".git/objects/9e/0a9235b0d70a8029098070007fb414cb52504e", ".git/objects/9e/bfcad2906aac4a23a7c9689a47b76723f5d152", ".git/objects/a6/578c95f2f474303464b572e9dac716432472b2", ".git/objects/a8/65ef5700ff04601c6fc40fa5ede3cc25534723", ".git/objects/aa/285cb176668c5e49c54c6e1d3cc27bd47fd4f4", ".git/objects/b8/e3828a1082137c4aa4595386bdfb73e3c75b9d", ".git/objects/c2/fb6afc000952b56354fe195682645000d2aea2", ".git/objects/c4/a0553ca0e3c4628e688ecb5e3304a8a8ac0c28", ".git/objects/c8/d49f83c4a32cff2d87dd4aa5f83eb7aac3a753", ".git/objects/ca/c25e8049075ed4bff993705acb4750b2b62ba9", ".git/objects/d2/ff2e939339eb3fb776e064c258e71dfa1cf396", ".git/objects/d7/cedf9e2a8ff35b5d7dafdc0f20daed9c65ce44", ".git/objects/e2/e81af59e3a6c4aa8daac62add62860ae776ba4", ".git/objects/e5/7c47d183ce5dda1a944c7ee1c19c8a0c4bb278", ".git/objects/eb/f4a4e1e50bb30731597f776e56b0ccb0c9959f", ".git/objects/f6/39d6f6cf883fde4b9052012919c1df3288c7da", ".git/objects/f8/2346f308f49053df108b7c31ac3089e8b4b4ac", ".git/objects/fb/4b193bb1cbe9041d2f00176f6caa6acfb1fc12", ".git/objects/pack/pack-aebf617a0b8e016433238d2f21f542bc5b21bd15.idx", ".git/objects/pack/pack-aebf617a0b8e016433238d2f21f542bc5b21bd15.pack", ".git/packed-refs", ".git/refs/heads/master", ".git/refs/remotes/origin/HEAD", ".gitignore", "History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/ulla", "config/website.yml", "config/website.yml.sample", "lib/math_extensions.rb", "lib/narray_extensions.rb", "lib/nmatrix_extensions.rb", "lib/string_extensions.rb", "lib/ulla.rb", "lib/ulla/cli.rb", "lib/ulla/environment.rb", "lib/ulla/environment_class_hash.rb", "lib/ulla/environment_feature.rb", "lib/ulla/environment_feature_array.rb", "lib/ulla/heatmap_array.rb", "script/console", "script/destroy", "script/generate", "script/txt2html", "test/test_helper.rb", "test/test_math_extensions.rb", "test/test_narray_extensions.rb", "test/test_nmatrix_extensions.rb", "test/test_string_extensions.rb", "test/test_ulla.rb", "test/ulla/test_cli.rb", "test/ulla/test_environment_class_hash.rb", "test/ulla/test_environment_feature.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.html.erb"]
  s.has_rdoc = true
  s.homepage = %q{http://www-cryst.bioc.cam.ac.uk/ulla}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ulla}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{'ulla' is a program for calculating environment-specific substitution tables from user providing environmental class definitions and sequence alignments with the annotations of the environment classes.}
  s.test_files = ["test/test_math_extensions.rb", "test/test_narray_extensions.rb", "test/test_nmatrix_extensions.rb", "test/test_string_extensions.rb", "test/ulla/test_cli.rb", "test/ulla/test_environment_class_hash.rb", "test/ulla/test_environment_feature.rb", "test/test_helper.rb", "test/test_ulla.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_runtime_dependency(%q<bio>, [">= 1.2.1"])
      s.add_runtime_dependency(%q<facets>, [">= 2.4.5"])
      s.add_runtime_dependency(%q<rmagick>, [">= 2.9.1"])
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<narray>, [">= 0.5.9.5"])
      s.add_dependency(%q<bio>, [">= 1.2.1"])
      s.add_dependency(%q<facets>, [">= 2.4.5"])
      s.add_dependency(%q<rmagick>, [">= 2.9.1"])
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<narray>, [">= 0.5.9.5"])
    s.add_dependency(%q<bio>, [">= 1.2.1"])
    s.add_dependency(%q<facets>, [">= 2.4.5"])
    s.add_dependency(%q<rmagick>, [">= 2.9.1"])
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
