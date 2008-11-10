class EnvironmentFeature < Struct.new(:name, :symbols, :labels, :constrained, :silent)

  def to_s
    values.join(";")
  end

  def constrained?
    constrained == "T"
  end

  def silent?
    silent == "T"
  end
end
