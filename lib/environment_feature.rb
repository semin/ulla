class EnvironmentFeature < Struct.new(:name, :symbols, :labels, :constrained, :silent)

  def to_s
    [name, symbols.join, labels.join, constrained, silent].join(";")
  end

  def constrained?
    constrained == "T"
  end

  def silent?
    silent == "T"
  end
end
