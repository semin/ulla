$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'bio'
require 'set'
require 'logger'
require 'narray'
require 'inline'
require 'stringio'
require 'pathname'
require 'getoptlong'
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


module Ulla
  VERSION = '0.9.9.2'
end
