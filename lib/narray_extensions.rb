require 'rubygems'
require 'narray'
require 'facets'

module NArrayExtensions

  def pretty_string(options={})
    opts = {:col_header => nil,
            :row_header => nil,
            :col_size   => 7}.merge(options)

    ("%-3s" % "#") + opts[:col_header].inject("") { |s, a|
      s + ("%#{opts[:col_size]}s" % a)
    } + "\n" +
      self.to_a.inject("%-3s" % opts[:row_header]) { |s, v|
      if v.is_a? Float
        s + ("%#{opts[:col_size]}.2f" % v)
      else
        s + ("%#{opts[:col_size]}d" % v)
      end
    }
  end
end

NArray.send(:include, NArrayExtensions)
