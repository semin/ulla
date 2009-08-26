module StringExtensions

  unless method_defined?(:blank?)
    # from Active Support library
    def blank?
      self !~ /\S/
    end
  end

  unless method_defined?(:start_with?)
    # from Ruby Facets library
    def start_with?(prefix)
      self.index(prefix) == 0
    end
  end

  def remove_internal_spaces
    gsub(/[\n|\r|\s]+/, '')
  end

  def rgb_to_integer
    if self.length == 7 # '#FF00FF'
      Integer(self.gsub('#', '0x'))
    else
      raise "#{self} doesn't seem to be a proper RGB code."
    end
  end
end

String.send :include, StringExtensions
