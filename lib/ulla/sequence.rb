module Ulla
  Sequence = Struct.new(:code, :data, :description) do
    def to_hash
      Hash[*members.zip(values).flatten]
    end
  end
end
