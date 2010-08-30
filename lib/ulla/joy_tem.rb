module Ulla
  class JoyTem

    attr_reader :file, :entries

    def initialize(file)
      @file     = file
      io        = File.exist?(file) ? File.open(file, 'r') : StringIO.new(file)
      @entries  = {}
      ent_code  = nil
      ent_desc  = nil
      ent_data  = nil
      parse_tag = nil

      io.each_with_index do |line, li|
        line.chomp!
        if    line =~ /^#/ || line =~ /^\s*$/
          next
        elsif line =~ /^>\S+;(\S+)/
          parse_tag = :desc
          ent_code  = $1
          @entries[ent_code] = {} unless @entries.has_key?(ent_code)
        elsif line =~ /^(\S+.*)/ && parse_tag == :desc
          parse_tag = :data
          ent_desc  = $1.strip
          @entries[ent_code][ent_desc]  = ''
        elsif line =~ /^\s*(\S+.*)/ && parse_tag == :data
          ent_data = $1.strip.gsub('*', '')
          @entries[ent_code][ent_desc] += ent_data
        else
          $logger.error "Cannot parse line #{li+1}: #{line}"
          exit 1
        end
      end
    end

    def entry_codes
      @entries.keys
    end

    def entry_descriptions
      @entries[entry_codes[0]].keys
    end

    def alignment_length
      @entries[entry_codes[0]][entry_descriptions[0]].length
    end

    def sequences
      seqs = []
      @entries.keys.each do |code|
        if @entries[code].has_key?('sequence')
          seqs << Sequence.new(@entries[code]['sequence'], code)
        else
          $logger.error "Cannot find 'sequence' data for #{code} in JOY template: #{@file}"
          exit 1
        end
      end
      seqs
    end

  end
end
