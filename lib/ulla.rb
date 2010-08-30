$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'inline'
require 'stringio'
require 'pathname'

require 'math_extensions'
require 'array_extensions'
require 'string_extensions'
require 'narray_extensions'
require 'nmatrix_extensions'

require 'ulla/environment'
require 'ulla/environment_class_hash'
require 'ulla/environment_feature'
require 'ulla/environment_feature_array'
require 'ulla/heatmap_array'


module Ulla
  VERSION = '0.9.9.1'
end
