module Egor
  class EnvironmentClassHash < Hash

    def group_by_non_residue_labels
      self.values.group_by { |env| env.label[1..-1] }
    end

    def groups_sorted_by_residue_labels
      group_by_non_residue_labels.to_a.sort_by { |env_group|
        env_group[0].split('').map_with_index { |l, i|
          $env_features[i + 1].labels.index(l)
        }
      }
    end

    def group_size
      group_by_non_residue_labels.size
    end
  end
end
