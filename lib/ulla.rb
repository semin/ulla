$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

<<<<<<< HEAD
require 'bio'
require 'set'
require 'logger'
require 'narray'
=======
require 'rubygems'
require 'bio'
require 'set'
>>>>>>> e5bd0d911ab38c672a1c0424fad4bf642468dbc4
require 'inline'
require 'narray'
require 'logger'
require 'narray'
require 'stringio'
require 'pathname'
require 'getoptlong'
<<<<<<< HEAD
require 'fork_manager'
require 'facets/enumerable'

require 'math_extensions'
require 'array_extensions'
require 'string_extensions'
require 'narray_extensions'
require 'nmatrix_extensions'

require 'ulla/esst'
require 'ulla/essts'
require 'ulla/joy_tem'
require 'ulla/sequence'
require 'ulla/heatmap_array'
require 'ulla/environment'
require 'ulla/environment_class_hash'
require 'ulla/environment_feature'
require 'ulla/environment_feature_array'
=======

require_relative 'math_extensions'
require_relative 'array_extensions'
require_relative 'string_extensions'
require_relative 'narray_extensions'
require_relative 'nmatrix_extensions'
>>>>>>> e5bd0d911ab38c672a1c0424fad4bf642468dbc4

require_relative 'ulla/environment'
require_relative 'ulla/environment_class_hash'
require_relative 'ulla/environment_feature'
require_relative 'ulla/environment_feature_array'
require_relative 'ulla/heatmap_array'
require_relative 'ulla/joy_tem'
require_relative 'ulla/sequence'

module Ulla
<<<<<<< HEAD
  VERSION = '0.9.9.2'
=======
  VERSION = '0.9.9.1'

  $logger       = Logger.new(STDOUT)
  $logger.level = Logger::WARN

  begin
    require 'rvg/rvg'
    include Magick
  rescue Exception => e
    $logger.warn "#{e.to_s.chomp} For this reason, heat maps cannot be generated."
    $no_rmagick = true
  end
>>>>>>> e5bd0d911ab38c672a1c0424fad4bf642468dbc4
end
