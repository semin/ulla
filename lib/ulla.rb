$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'bio'
require 'set'
require 'inline'
require 'narray'
require 'logger'
require 'narray'
require 'stringio'
require 'pathname'
require 'getoptlong'

require_relative 'math_extensions'
require_relative 'array_extensions'
require_relative 'string_extensions'
require_relative 'narray_extensions'
require_relative 'nmatrix_extensions'

require_relative 'ulla/environment'
require_relative 'ulla/environment_class_hash'
require_relative 'ulla/environment_feature'
require_relative 'ulla/environment_feature_array'
require_relative 'ulla/heatmap_array'
require_relative 'ulla/joy_tem'
require_relative 'ulla/sequence'

module Ulla
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
end
