module Ulla
  class Essts

    attr_reader :file, :type, :aa_symbols,
                :environments, :essts, :total_table,
                :number_of_environments, :number_of_alignments

    def initialize(file, type = :logo)
      @file         = file
      @type         = type
      @environments = []
      @essts        = []
      @total_table  = nil
      parse_tag     = nil

      IO.readlines(@file).each_with_index do |line, li|
        line.chomp!
        if    line =~ /^#\s+(ACDEFGHIKLMNPQRSTV\w+)/
          @aa_symbols = $1.split('')
        elsif line =~ /^#\s+(.*;\w+;\w+;[T|F];[T|F])/
          elems = $1.split(';')
          @environments << (env = OpenStruct.new)
          @environments[-1].name        = elems[0]
          @environments[-1].values      = elems[1].split('')
          @environments[-1].labels      = elems[2].split('')
          @environments[-1].constraind  = elems[3] == 'T' ? true : false
          @environments[-1].silent      = elems[4] == 'T' ? true : false
        elsif line =~ /^#\s+Total\s+number\s+of\s+environments:\s+(\d+)/
          @number_of_environments = Integer($1)
        elsif line =~ /^#\s+Number\s+of\s+alignments:\s+(\d+)/
          @number_of_alignments = Integer($1)
        elsif line =~ /^#/ # skip other comments!
          next
        elsif line =~ /^>Total/i
          @total_table  = Esst.new(type, 'total', @essts.size, @aa_symbols)
          parse_tag     = :tot_row
        elsif line =~ /^>Total\s+(\S+)/i
          @total_table  = Esst.new(type, 'total', Integer($1), @aa_symbols)
          parse_tag     = :tot_row
        elsif line =~ /^>(\S+)\s+(\S+)/
          break if parse_tag == :tot_row
          @essts    << Esst.new(type, $1, Integer($2), @aa_symbols)
          parse_tag = :esst_row
        elsif line =~ /^(\S+)\s+(\S+.*)$/ && (parse_tag == :esst_row || parse_tag == :tot_row)
          row_name    = $1
          row_values  = $2.strip.split(/\s+/).map { |v| Float(v) }
          if parse_tag == :esst_row
            @essts[-1].rownames << row_name
            @essts[-1].matrix = NMatrix[*(@essts[-1].matrix.to_a << row_values)]
          elsif parse_tag == :tot_row
            @total_table.rownames << row_name
            @total_table.matrix = NMatrix[*(@total_table.matrix.to_a << row_values)]
          else
            $logger.error "Something wrong at line #{li}: #{line}"
            exit 1
          end
        else
          raise "Something wrong at line, #{li}: #{line}"
        end
      end
    end

    def colnames
      @essts[0].colnames
    end

    def rownames
      @essts[0].rownames
    end

    def [](index)
      case index
      when Integer
        @essts[index]
      when String
        @essts.find { |e| e.label == index }
      else
        $logger.error "#{index} is not available for indexing ESSTs"
        exit
      end
    end

  end
end
