module MathExtensions

  def log2(val)
    log(val) / log(2)
  end

end

Math.extend(MathExtensions)
