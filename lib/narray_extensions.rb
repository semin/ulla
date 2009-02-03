#require 'rubygems'
require 'narray'
require 'facets'

module NArrayExtensions

  def pretty_string(opts={})
    { :col_header   => nil,
      :row_header   => nil }.merge!(opts)

    ("%-3s" % "#") + opts[:col_header].inject("") { |s, a| s + ("%7s" % a) } + "\n" +
      self.to_a.inject("%-3s" % opts[:row_header]) { |s, v|
      if v.is_a? Float
        s + ("%7.2f" % v)
      else
        s + ("%7d" % v)
      end
    }
  end
end

NArray.send(:include, NArrayExtensions)
