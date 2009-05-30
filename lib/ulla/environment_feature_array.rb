module Ulla
  class EnvironmentFeatureArray < Array

    def label_combinations
      self.inject([]) { |sum, ec|
        sum << ec.labels
      }.inject { |pro, lb|
        pro.product(lb)
      }
    end

    def label_combinations_without_aa_type
      self[1..-1].inject([]) { |sum, ec|
        sum << ec.labels
      }.inject { |pro, lb|
        pro.product(lb)
      }
    end
  end
end
