module Ulla
  class EnvironmentFeatureArray < Array

    def label_combinations
      self.inject([]) { |sum, ec|
        sum << ec.labels
      }.inject { |pro, lb|
        pro.product(lb)
      }
    end
  end
end
