module ArrayExtensions

  # from Active Support library
  def sum(identity = 0, &block)
    return identity unless size > 0

    if block_given?
      map(&block).sum
    else
      inject { |sum, element| sum + element }
    end
  end

end

Array.send :include, ArrayExtensions
