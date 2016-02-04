require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/ulla.rb'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'ulla' do
  self.developer 'Semin Lee', 'seminlee@gmail.com'
  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.extra_deps           = [
    ['narray',        '>= 0.5.9.5'],
    ['bio',           '>= 1.2.1'],
    ['rmagick',       '>= 2.9.1'],
  ]
end

require 'newgem/tasks'
Dir['tasks/*.rake'].each { |t| load t }
