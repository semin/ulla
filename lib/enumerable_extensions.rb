module EnumerableExtensions
  def cart_prod( *args )
    args.inject([[]]) { |old, lst| new = [] lst.each { |e| new += old.map { |c| c.dup << e } } new }
  end
end

Enumerable.extend(EnumerableExtensions)
