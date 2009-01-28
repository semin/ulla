module StringExtensions

  def remove_internal_spaces
    gsub(/[\n|\r|\s]+/, '')
  end
end

String.send :include, StringExtensions

