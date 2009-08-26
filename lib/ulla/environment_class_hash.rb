module Ulla
  class EnvironmentClassHash < Hash

    def group_by_non_residue_labels
      self.values.group_by { |env| env.label[1..-1] }
    end

    def groups_sorted_by_residue_labels
      group_by_non_residue_labels.to_a.sort_by { |env_group|
        env_group[0].gsub('-', '').split('').each_with_index.map { |l, i|
          if i < ($env_features.size - 1)
            $env_features[i + 1].labels.index(l)
          else
            $env_features[i + 2 - $env_features.size].labels.index(l)
          end
        }
      }
    end

    def group_size
      group_by_non_residue_labels.size
    end
  end
end
