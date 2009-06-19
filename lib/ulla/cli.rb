require 'rubygems'
require 'getoptlong'
require 'logger'
require 'narray'
require 'bio'
require 'set'
require 'facets'

# This is a module for an actual command line interpreter for Ulla
# ---
# Copyright (C) 2008-9 Semin Lee
module Ulla
  class CLI
    class << self

      # :nodoc:
      def print_version
        puts VERSION
      end

      # Print Ulla's Usage on the screen
      #
      # :call-seq:
      #   Ulla::CLI::print_usage
      #
      def print_usage
        puts <<-USAGE
ulla: a program to calculate environment-specific amino acid substitution tables.

Usage:
    ulla [ options ] -l TEMLIST-file -c CLASSDEF-file
        or
    ulla [ options ] -f TEM-file -c CLASSDEF-file

Options:
    --tem-file (-f) FILE: a tem file
    --tem-list (-l) FILE: a list for tem files
    --classdef (-c) FILE: a file for the defintion of environments (default: 'classdef.dat')
    --outfile (-o) FILE: output filename (default 'allmat.dat')
    --weight (-w) INTEGER: clustering level (PID) for the BLOSUM-like weighting (default: 60)
    --noweight: calculate substitution counts with no weights
    --environment (-e) INTEGER:
        0 for considering only substituted amino acids' environments (default)
        1 for considering both substituted and substituting amino acids' environments
    --smooth (-s) INTEGER:
        0 for partial smoothing (default)
        1 for full smoothing
    --p1smooth: perform smoothing for p1 probability calculation when partial smoothing
    --nosmooth: perform no smoothing operation
    --cys (-y) INTEGER:
        0 for using C and J only for structure (default)
        1 for both structure and sequence
        2 for using only C for both (must be set when you have no 'disulphide' or 'disulfide' annotation in templates)
    --output INTEGER:
        0 for raw counts (no smoothing performed)
        1 for probabilities
        2 for log-odds (default)
    --noroundoff: do not round off log odds ratio
    --scale INTEGER: log-odds matrices in 1/n bit units (default 3)
    --sigma DOUBLE: change the sigma value for smoothing (default 5.0)
    --autosigma: automatically adjust the sigma value for smoothing
    --add DOUBLE: add this value to raw counts when deriving log-odds without smoothing (default 0)
    --pidmin DOUBLE: count substitutions only for pairs with PID equal to or greater than this value (default none)
    --pidmax DOUBLE: count substitutions only for pairs with PID smaller than this value (default none)
    --heatmap INTEGER:
        0 create a heat map file for each substitution table
        1 create one big file containing all heat maps from substitution tables
        2 do both 0 and 1
    --heatmap-format INTEGER:
        0 for Portable Network Graphics (PNG) Format (default)
        1 for Graphics Interchange Format (GIF)
        2 for Joint Photographic Experts Group (JPEG) Format
        3 for Microsoft Windows bitmap (BMP) Format
        4 for Portable Document Format (PDF)
    --heatmap-columns INTEGER: number of tables to print in a row when --heatmap 1 or 2 set (default: sqrt(no. of tables))
    --heatmap-stem STRING: stem for a file name when --heatmap 1 or 2 set (default: 'heatmap')
    --heatmap-values: print values in the cells when generating heat maps
    --verbose (-v) INTEGER
        0 for ERROR level
        1 for WARN or above level (default)
        2 for INFO or above level
        3 for DEBUG or above level
    --version: print version
    --help (-h): show help

        USAGE
      end

      # Calculate PID between two sequences
      #
      # :call-seq:
      #   Ulla::CLI::calculate_pid(seq1, seq2) -> Float
      #
      def calculate_pid(seq1, seq2, unit)
        aas1  = seq1.scan(/\w{#{unit}}/)
        aas2  = seq2.scan(/\w{#{unit}}/)
        cols  = aas1.zip(aas2)
        gap   = ($gap || '-') * unit
        align = 0 # no. of aligned columns
        ident = 0 # no. of identical columns
        intgp = 0 # no. of internal gaps

        cols.each do |col|
          if (col[0] != gap) && (col[1] != gap)
            align += 1
            if col[0] == col[1]
              ident += 1
            end
          elsif (((col[0] == gap) && (col[1] != gap)) ||
                 ((col[0] != gap) && (col[1] == gap)))
            intgp += 1
          end
        end

        pid = 100.0 * ident.to_f / (align + intgp)
      end

      # :nodoc:
      def execute(arguments=[])
        #
        # * Abbreviations in the codes
        #
        # env: environment
        # tem: (FUGUE) template
        # classdef: (envlironment) class definition
        # aa: amino acid
        # aa: weighted amino acid
        # tot: total
        # rel: relative
        # jnt: joint
        # cnt: count
        # mut: mutation
        # mutb: mutability
        # freq: frequency
        # prob: probability
        # logo: log odds ratio
        # opts: options
        # fh: file handle
        # ff: flat file
        # ali: alignment
        # mat: matrix
        # arr: array


        # Part 1.
        #
        # Global variables and their default values
        #

        $logger       = Logger.new(STDOUT)
        $logger.level = Logger::WARN

        # default set of 21 amino acids including J (Cysteine, the free thiol form)
        $amino_acids    = 'ACDEFGHIKLMNPQRSTVWYJ'.split('')
        $gap            = '-'
        $tem_list       = nil
        $tem_file       = nil
        $environment    = 0
        $col_size       = nil
        $classdef       = 'classdef.dat'
        $outfile        = 'allmat.dat'
        $outfh          = nil # file hanfle for outfile
        $output         = 2 # default: log odds matrix
        $ali_size       = 0
        $tot_aa         = 0
        $sigma          = 5.0
        $autosigma      = false
        $weight         = 60
        $noweight       = false
        $smooth         = :partial
        $nosmooth       = false
        $noroundoff     = false
        $p1smooth       = false
        $scale          = 3
        $pidmin         = nil
        $pidmax         = nil
        $scale          = 3
        $add            = nil
        $cys            = 0
        $targetenv      = false
        $penv           = false
        $heatmap        = nil
        $heatmapcol     = nil
        $heatmapformat  = 'png'
        $heatmapstem    = 'heatmaps'
        $heatmapvalues  = false
        $rvg_width      = 550
        $rvg_height     = 650
        $canvas_width   = 550
        $canvas_height  = 650
        $cell_width     = 20
        $cell_height    = 20

        $aa_tot_cnt   = Hash.new(0)
        $aa_mut_cnt   = Hash.new(0)
        $aa_mutb      = {}
        $aa_rel_mutb  = {}
        $aa_tot_freq  = {}
        $smooth_prob  = {}
        $tot_cnt_mat  = nil
        $tot_prob_mat = nil
        $tot_logo_mat = nil
        $tot_smooth_prob = {}

        # minimum ratio of amino acid count to sigma value
        $min_cnt_sigma_ratio = 500.0

        #
        # Part 1 END
        #

        # Part 2.
        #
        # Parsing options
        #

        opts = GetoptLong.new(
          [ '--help',         '-h', GetoptLong::NO_ARGUMENT ],
          [ '--tem-list',     '-l', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--tem-file',     '-f', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--classdef',     '-c', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--environment',  '-e', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--smooth',       '-s', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--nosmooth',           GetoptLong::NO_ARGUMENT ],
          [ '--p1smooth',           GetoptLong::NO_ARGUMENT ],
          [ '--weight',       '-w', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--noweight',           GetoptLong::NO_ARGUMENT ],
          [ '--noroundoff',         GetoptLong::NO_ARGUMENT ],
          [ '--sigma',              GetoptLong::REQUIRED_ARGUMENT ],
          [ '--autosigma',          GetoptLong::NO_ARGUMENT ],
          [ '--add',                GetoptLong::REQUIRED_ARGUMENT ],
          [ '--heatmap',            GetoptLong::REQUIRED_ARGUMENT ],
          [ '--heatmap-stem',       GetoptLong::REQUIRED_ARGUMENT ],
          [ '--heatmap-format',     GetoptLong::REQUIRED_ARGUMENT ],
          [ '--heatmap-columns',    GetoptLong::REQUIRED_ARGUMENT ],
          [ '--heatmap-values',     GetoptLong::NO_ARGUMENT ],
          [ '--output',             GetoptLong::REQUIRED_ARGUMENT ],
          [ '--targetenv',    '-t', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--cys',          '-y', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--penv',               GetoptLong::NO_ARGUMENT ],
          [ '--outfile',      '-o', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--verbose',      '-v', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--version',            GetoptLong::NO_ARGUMENT ]
        )

        begin
          opts.each do |opt, arg|
            case opt
            when '--help'
              print_usage
              exit 0
            when '--tem-list'
              $tem_list     = arg
            when '--tem-file'
              $tem_file     = arg
            when '--classdef'
              $classdef     = arg
            when '--environment'
              $environment  = arg.to_i
            when '--output'
              $output       = arg.to_i
            when '--outfile'
              $outfile      = arg
            when '--cys'
              $cys          = arg.to_i
            when '--targetenv'
              $targetenv    = (arg.to_i == 1) ? true : false
            when '--weight'
              $weight       = arg.to_i
            when '--sigma'
              $sigma        = arg.to_f
            when '--autosigma'
              $autosigma    = true
            when '--pidmin'
              $pidmin       = arg.to_f
            when '--pidmax'
              $pidmax       = arg.to_f
            when '--noweight'
              $noweight     = true
            when '--noroundoff'
              $noroundoff   = true
            when '--smooth'
              $smooth       = (arg.to_i == 1) ? :full : :partial
            when '--nosmooth'
              $nosmooth     = true
            when '--p1smooth'
              $p1smooth     = true
            when '--scale'
              $scale        = arg.to_f
            when '--add'
              $add          = arg.to_f
            when '--penv'
              warn "--penv option is not supported."
              exit 1
              $penv         = true
            when '--heatmap'
              $heatmap      = case arg.to_i
                              when (0..2) then arg.to_i
                              else
                                warn "--heatmap #{arg.to_i} is not allowed."
                                exit1
                              end
            when '--heatmap-columns'
              $heatmapcol   = arg.to_i
            when '--heatmap-stem'
              $heatmapstem  = arg.to_s
            when '--heatmap-format'
              $heatmapformat   = case arg.to_i
                              when 0 then 'png'
                              when 1 then 'gif'
                              when 2 then 'jpg'
                              when 3 then 'bmp'
                              when 4 then 'pdf'
                              else
                                warn "--heatmap-format #{arg.to_i} is not supported."
                                exit 1
                              end
            when '--heatmap-values'
              $heatmapvalues   = true
            when '--verbose'
              $logger.level = case arg.to_i
                              when 0 then Logger::ERROR
                              when 1 then Logger::WARN
                              when 2 then Logger::INFO
                              when 3 then Logger::DEBUG
                              else
                                warn "--verbose (-v) #{arg.to_i} is not supported."
                                exit 1
                              end
            when '--version'
              print_version
              exit 0
            end
          end
        rescue
          # invalid option
          exit 1
        end

        # when arguments are nonsense, print usage
        if ((ARGV.length != 0) ||
            (!$tem_list && !$tem_file) ||
            ($tem_list && $tem_file))
          print_usage
          exit 1
        end

        # warn if any mandatory input file is missing
        if $tem_list && !File.exist?($tem_list)
          warn "Cannot find template list file, #{$tem_list}"
          exit 1
        end

        if $tem_file && !File.exist?($tem_file)
          warn "Cannot find template file, #{$tem_file}"
          exit 1
        end

        if $classdef && !File.exist?($classdef)
          warn "Cannot find environment class definition file, #{$classdef}"
          exit 1
        end

	require 'math_extensions'
	require 'string_extensions'
	require 'narray_extensions'
	require 'nmatrix_extensions'

	require 'ulla/environment'
	require 'ulla/environment_class_hash'
	require 'ulla/environment_feature'
	require 'ulla/environment_feature_array'
	require 'ulla/heatmap_array'

        #
        # Part 2 END
        #


        # Part 3.
        #
        # Reading Environment Class Definition File
        #

        # if --cys option 2, then we don't care about 'J' (for both Cystine and Cystine)
        if $cys == 2
          $amino_acids = 'ACDEFGHIKLMNPQRSTVWY'.delete('J')
        end

        # create an EnvironmentFeatureArray object for storing all environment
        # features
        $env_features = EnvironmentFeatureArray.new

        # an array for storing indexes of constrained environment features
        $cst_features = []

        # add substituted amino acid (aa1) in a substitution to the environment
        # feature list
        $env_features << EnvironmentFeature.new('sequence',
                                                $amino_acids,
                                                $amino_acids,
                                                'F',
                                                'F')

        # read environment class definiton file and store them into
        # the hash prepared above
        env_index = 1

        IO.foreach($classdef) do |line|
          line.chomp!
          if line.start_with?('#') || line.blank?
            next
          elsif (env_ftr = line.split(/;/)).length == 5
            $logger.info "An environment feature, #{line} detected."
            if env_ftr[-1] == 'T'
              # skip silenced environment feature
              $logger.warn "The environment feature, #{line} silent."
              next
            end
            if env_ftr[-2] == 'T'
              $cst_features << env_index
              $logger.warn "The environment feature, #{line} constrained."
            end
            $env_features << EnvironmentFeature.new(env_ftr[0],
                                                    env_ftr[1].split(''),
                                                    env_ftr[2].split(''),
                                                    env_ftr[3],
                                                    env_ftr[4])
            env_index += 1
          else
            $logger.error "\"#{line}\" doesn't seem to be a proper format for " +
                          "an environment class definition."
            exit 1
          end
        end

        # set the size of amino acid column unit, extended gap
        # and extended amino acid labels
        $col_size         = $environment == 1 ? $env_features.size : 1
        $ext_gap          = $gap * $col_size
        $ext_amino_acids  = []

        # a hash for storing all environment classes
        $env_classes = EnvironmentClassHash.new

        # generate all possible combinations of environment labels, and store
        # every environment class into the hash prepared above with the label
        # as a key
        $env_features.label_combinations.each_with_index do |ef1, i|
          key1 = ef1.flatten.join
          $ext_amino_acids << key1

          if $environment == 0
            $env_classes[key1] = Environment.new(i, key1, $amino_acids)
          else
            # when considering both substituted and substituting amino acids' environtments,
            # add target (substituting) aa's environment label
            $env_features.label_combinations_without_aa_type.each_with_index do |ef2, j|
              key2 = key1 + "-" + ef2.flatten.join
              $env_classes[key2] = Environment.new(i + j, key2, $amino_acids)
            end
          end
        end

        #
        # Part 3 END
        #


        # Part 4.
        #
        # Reading TEM file or TEMLIST list file and couting substitutions
        #

        # a global file handle for output
        $outfh = File.open($outfile, 'w')

        if $tem_file
          $tem_list_io = StringIO.new($tem_file)
        end

        if $tem_list
          $tem_list_io = File.open($tem_list)
        end

        $tem_list_io.each_line do |tem_file|
          tem_file.chomp!

          ali = Bio::Alignment::OriginalAlignment.new
          ff  = Bio::FlatFile.auto(tem_file)

          ff.each_entry do |pir|
            if (pir.definition == 'sequence') || (pir.definition == 'structure')
              ali.add_seq(pir.data.remove_internal_spaces, pir.entry_id)
            end
          end

          if ali.size < 2
            $logger.warn "Skipped #{tem_file} which has only one unique entry."
            next
          end

          $ali_size   += 1
          env_labels  = {}
          disulphide  = {}

          ali.each_pair do |key, seq|
            # check disulphide bond environment first!
            ff.rewind
            ff.each_entry do |pir|
              if ((pir.entry_id == key) &&
                  ((pir.definition == "disulphide") ||
                   (pir.definition == "disulfide")))
                disulphide[key] = pir.data.remove_internal_spaces.split('')
              end
            end

            $env_features.each_with_index do |ec, ei|
              env_labels[key] = [] unless env_labels.has_key?(key)

              ff.rewind
              ff.each_entry do |pir|
                if (pir.entry_id == key) && (pir.definition == ec.name)
                  labels = pir.data.remove_internal_spaces.split('').map_with_index do |sym, pos|
                    if sym == '-'
                      '-'
                    elsif sym == 'X' || sym == 'x'
                      'X'
                    else
                      if ei == 0 # Amino Acid Environment Feature
                        (disulphide.has_key?(key) && (disulphide[key][pos] == 'F') && (sym == 'C') && ($cys != 2)) ? 'J' : sym
                      else
                        ec.labels[ec.symbols.index(sym)]
                      end
                    end
                  end

                  if env_labels[key].empty?
                    env_labels[key] = labels
                  else
                    env_labels[key].each_with_index { |e, i| env_labels[key][i] = e + labels[i] }
                  end
                end
              end
            end
          end

          if $noweight
            ali.each_pair do |id1, seq1|
              if $environment == 1
                seq1 = seq1.split('').map_with_index { |aa, pos| aa == $gap ? $ext_gap : env_labels[id1][pos] }.join
              end

              ali.each_pair do |id2, seq2|
                if id1 != id2
                  if $environment == 1
                    seq2 = seq2.split('').map_with_index { |aa, pos| aa == $gap ? $ext_gap : env_labels[id2][pos] }.join
                  end

                  pid = calculate_pid(seq1, seq2, $col_size)
                  s1  = seq1.scan(/\S{#{$col_size}}/)
                  s2  = seq2.scan(/\S{#{$col_size}}/)

                  # check PID_MIN
                  if $pidmin && (pid < $pidmin)
                    $logger.info  "Skip alignment between #{id1} and #{id2} having PID, #{pid}% less than PID_MIN, #{$pidmin}."
                    next
                  end

                  # check PID_MAX
                  if $pidmax && (pid > $pidmax)
                    $logger.info  "Skip alignment between #{id1} and #{id2} having PID, #{pid}% greater than PID_MAX, #{$pidmax}."
                    next
                  end

                  s1.each_with_index do |aa1, pos|
                    aa2 = s2[pos]

                    if env_labels[id1][pos].include?('X')
                      $logger.info "Substitutions from #{id1}-#{pos}-#{aa1[0].chr} were masked."
                      next
                    end

                    if env_labels[id2][pos].include?('X')
                      $logger.info "Substitutions to #{id2}-#{pos}-#{aa2[0].chr} were masked."
                      next
                    end

                    unless $amino_acids.include?(aa1[0].chr)
                      $logger.warn "#{id1}-#{pos}-#{aa1[0].chr} is not a standard amino acid." unless aa1 == $ext_gap
                      next
                    end

                    unless $amino_acids.include?(aa2[0].chr)
                      $logger.warn "#{id1}-#{pos}-#{aa2[0].chr} is not a standard amino acid." unless aa2 == $ext_gap
                      next
                    end

                    aa1       = (disulphide.has_key?(id1) && (disulphide[id1][pos] == 'F') && (aa1[0].chr == 'C') && ($cys != 2)) ? 'J' + aa1[1..-1] : aa1
                    aa2       = (disulphide.has_key?(id2) && (disulphide[id2][pos] == 'F') && (aa2[0].chr == 'C') && ($cys != 2)) ? 'J' + aa2[1..-1] : aa2
                    env_label = $environment == 1 ? aa1 + '-' + aa2[1..-1] : env_labels[id1][pos]

                    if $cst_features.empty?
                      $env_classes[env_label].increase_residue_count(aa2[0].chr)
                    elsif (env_labels[id1][pos].split('').values_at(*$cst_features) == env_labels[id2][pos].split('').values_at(*$cst_features))
                      $env_classes[env_label].increase_residue_count(aa2[0].chr)
                    else
                      $logger.debug "Skipped #{id1}-#{pos}-#{aa1[0].chr} and #{id2}-#{pos}-#{aa2[0].chr} having different symbols for constrained environment features each other."
                      next
                    end

                    $aa_tot_cnt.has_key?(aa1) ? $aa_tot_cnt[aa1] += 1 : $aa_tot_cnt[aa1] = 1
                    $aa_mut_cnt.has_key?(aa1) ? $aa_mut_cnt[aa1] += 1 : $aa_mut_cnt[aa1] = 1 if aa1 != aa2

                    $logger.debug "#{id1}-#{pos}-#{aa1[0].chr} -> #{id2}-#{pos}-#{aa2[0].chr} substitution count (1) was added to the environments class, #{env_label}."
                  end
                end
              end
            end
          else
            # BLOSUM-like weighting
            clusters  = []
            ext_ali   = Bio::Alignment::OriginalAlignment.new

            ali.each_pair do |key, seq|
              clusters << [key]
              if $environment == 1
                ext_seq = seq.split('').map_with_index { |aa, pos| aa == $gap ? $ext_gap : env_labels[key][pos] }.join
                ext_ali.add_seq(ext_seq, key)
              end
            end

            if $environment == 1
              ali = ext_ali
            end

            # a loop for single linkage clustering
            begin
              continue = false
              0.upto(clusters.size - 2) do |i|
                indexes = []
                (i + 1).upto(clusters.size - 1) do |j|
                  found = false
                  clusters[i].each do |c1|
                    clusters[j].each do |c2|
                      if calculate_pid(ali[c1], ali[c2], $col_size) >= $weight
                        indexes << j
                        found = true
                        break
                      end
                    end
                    break if found
                  end
                end

                unless indexes.empty?
                  continue  = true
                  group     = clusters[i]
                  indexes.each do |k|
                    group       = group.concat(clusters[k])
                    clusters[k] = nil
                  end
                  clusters[i] = group
                  clusters.compact!
                end
              end
            end while(continue)

            if clusters.size < 2
              $logger.debug "Skipped #{tem_file} which has only one cluster at the #{$weight} PID level."
              next
            end

            clusters.combination(2).each do |cluster1, cluster2|
              cluster1.each do |id1|
                cluster2.each do |id2|
                  seq1 = ali[id1].scan(/\S{#{$col_size}}/)
                  seq2 = ali[id2].scan(/\S{#{$col_size}}/)

                  seq1.each_with_index do |aa1, pos|
                    aa2 = seq2[pos]

                    if env_labels[id1][pos].include?('X')
                      $logger.debug "All substitutions from #{id1}-#{pos}-#{aa1[0].chr} are masked."
                      next
                    end

                    if env_labels[id2][pos].include?('X')
                      $logger.debug "All substitutions to #{id2}-#{pos}-#{aa2[0].chr} are masked."
                      next
                    end

                    unless $amino_acids.include?(aa1[0].chr)
                      $logger.warn "#{id1}-#{pos}-#{aa1[0].chr} is not standard amino acid." unless aa1 == $ext_gap
                      next
                    end

                    unless $amino_acids.include?(aa2[0].chr)
                      $logger.warn "#{id2}-#{pos}-#{aa2[0].chr} is not standard amino acid." unless aa2 == $ext_gap
                      next
                    end

                    aa1         = (disulphide.has_key?(id1) && (disulphide[id1][pos] == 'F') && (aa1[0].chr == 'C') && ($cys != 2)) ? 'J' + aa1[1..-1] : aa1
                    aa2         = (disulphide.has_key?(id2) && (disulphide[id2][pos] == 'F') && (aa2[0].chr == 'C') && ($cys != 2)) ? 'J' + aa2[1..-1] : aa2
                    cnt1        = 1.0 / cluster1.size.to_f
                    cnt2        = 1.0 / cluster2.size.to_f
                    jnt_cnt     = cnt1 * cnt2
                    env_label1  = $environment == 1 ? aa1 + '-' + aa2[1..-1] : env_labels[id1][pos]
                    env_label2  = $environment == 1 ? aa2 + '-' + aa1[1..-1] : env_labels[id2][pos]

                    if $cst_features.empty?
                      $env_classes[env_label1].increase_residue_count(aa2[0].chr, jnt_cnt) #rescue $logger.error "Something wrong with #{tem_file}-#{id2}-#{pos}-#{aa2}-#{env_label2}"
                      $env_classes[env_label2].increase_residue_count(aa1[0].chr, jnt_cnt) #rescue $logger.error "Something wrong with #{tem_file}-#{id2}-#{pos}-#{aa2}-#{env_label2}"
                    elsif (env_labels[id1][pos].split('').values_at(*$cst_features) == env_labels[id2][pos].split('').values_at(*$cst_features))
                      $env_classes[env_label1].increase_residue_count(aa2[0].chr, jnt_cnt)
                      $env_classes[env_label2].increase_residue_count(aa1[0].chr, jnt_cnt)
                    else
                      $logger.debug "Skipped #{id1}-#{pos}-#{aa1[0].chr} and #{id2}-#{pos}-#{aa2[0].chr} having different symbols for constrained environment features each other."
                      next
                    end

                    $aa_tot_cnt.has_key?(aa1) ? $aa_tot_cnt[aa1] += cnt1 : $aa_tot_cnt[aa1] = cnt1
                    $aa_tot_cnt.has_key?(aa2) ? $aa_tot_cnt[aa2] += cnt2 : $aa_tot_cnt[aa2] = cnt2
                    $aa_mut_cnt.has_key?(aa1) ? $aa_mut_cnt[aa1] += cnt1 : $aa_mut_cnt[aa1] = cnt1 if aa1 == aa2
                    $aa_mut_cnt.has_key?(aa2) ? $aa_mut_cnt[aa2] += cnt2 : $aa_mut_cnt[aa2] = cnt2 if aa1 == aa2

                    $logger.debug "#{id1}-#{pos}-#{aa1[0].chr} -> #{id2}-#{pos}-#{aa2[0].chr} substitution count (#{"%.2f" % jnt_cnt}) was added to the environments class, #{env_label1}."
                    $logger.debug "#{id2}-#{pos}-#{aa2[0].chr} -> #{id1}-#{pos}-#{aa1[0].chr} substitution count (#{"%.2f" % jnt_cnt}) was added to the environments class, #{env_label2}."
                  end
                end
              end
            end
          end
          $logger.info "Analysing #{tem_file} done."
        end

        # print out default header
        $outfh.puts <<HEADER
# Environment-specific amino acid substitution matrices
# Creator: ulla version #{VERSION}
# Creation Date: #{Time.now.strftime("%d/%m/%Y %H:%M")}
#
# Definitions for structural environments:
# #{$env_features.size - 1} features used
#
HEADER

        $env_features[1..-1].each { |e| $outfh.puts "# #{e}" }

        $outfh.puts <<HEADER
# (read in from #{$classdef})
#
# Number of alignments: #{$ali_size}
# (list of .tem files read in from #{$tem_list})
#
# Total number of environments: #{Integer($env_classes.size / $amino_acids.size)}
#
# There are #{$amino_acids.size} amino acids considered.
# #{$amino_acids.join}
# 
HEADER

        if $amino_acids.include? 'J'
          $outfh.puts <<HEADER
# C: Cystine (the disulfide-bonded form)
# J: Cysteine (the free thiol form)
#
HEADER
        end

        if $noweight
          $outfh.puts '# Weighting scheme: none'
        else
          $outfh.puts "# Weighting scheme: clustering at PID #{$weight} level"
        end

        if $environment == 0
          $outfh.puts '#'
          $outfh.puts '# Considered environments: substituted a.a.'
        else
          $outfh.puts '#'
          $outfh.puts '# Considered environments: substituted a.a. and substituting a.a.'
        end

        # calculate amino acid frequencies and mutabilities, and
        # print them as default statistics in the header part
        if $environment == 0
          ala_factor  = if $aa_tot_cnt['A'] == 0
                          0.0
                        elsif $aa_mut_cnt['A'] == 0
                          0.0
                        else
                          100.0 * $aa_tot_cnt['A'] / $aa_mut_cnt['A'].to_f
                        end
        end

        $tot_aa = $aa_tot_cnt.values.sum

        $outfh.puts '#'
        $outfh.puts "# Total amino acid frequencies:\n"

        if $environment == 0
          $outfh.puts "# %-3s %9s %9s %5s %8s %8s" % %w[RES TOT_OBS MUT_OBS MUTB REL_MUTB REL_FREQ]
        else
          $outfh.puts "# %-3s %-#{$env_features.size}s %9s %9s %8s" % %w[RES ENV TOT_OBS MUT_OBS REL_FREQ]
        end

        min_cnt   = 0
        min_sigma = nil
        aas       = $environment == 0 ? $amino_acids : $ext_amino_acids

        aas.each do |aa|
          if ($aa_tot_cnt[aa] / $sigma) < $min_cnt_sigma_ratio
            if $aa_tot_cnt[aa] > 0 and min_cnt > $aa_tot_cnt[aa]
              min_cnt = $aa_tot_cnt[aa]
            elsif min_cnt == 0
              min_cnt = 1
            end

            min_sigma = min_cnt / $min_cnt_sigma_ratio

            if $environment == 0
              $logger.warn  "The current sigma value, #{$sigma} seems to be too big for " +
                            "the total count (#{"%.2f" % $aa_tot_cnt[aa]}) of amino acid, #{aa}."
            else
              $logger.warn  "The current sigma value, #{$sigma} seems to be too big for " +
                            "the total count (#{"%.2f" % $aa_tot_cnt[aa]}) of amino acid, #{aa[0].chr} under the environment class #{aa[1..-1]}."
            end
          end

          if $environment == 0
            $aa_mutb[aa]     = ($aa_tot_cnt[aa] == 0) ? 1.0 : ($aa_mut_cnt[aa] / $aa_tot_cnt[aa].to_f)
            $aa_rel_mutb[aa] = $aa_mutb[aa] * ala_factor
          end

          $aa_tot_freq[aa] = ($aa_tot_cnt[aa] == 0) ? 0.0 : ($aa_tot_cnt[aa] / $tot_aa.to_f)
        end

        if min_cnt > 0
          $logger.warn "We recommend you to use a sigma value equal to or smaller than #{min_sigma}."

          if $autosigma
            $logger.warn "The sigma value has been changed from #{$sigma} to #{min_sigma}."
            $sigma = min_sigma
          end
        end

        aas.each do |aa|
          columns = $environment == 0 ?
                    [aa, $aa_tot_cnt[aa], $aa_mut_cnt[aa], $aa_mutb[aa], $aa_rel_mutb[aa], $aa_tot_freq[aa]] :
                    [aa[0].chr, aa[1..-1], $aa_tot_cnt[aa], $aa_mut_cnt[aa], $aa_tot_freq[aa]]

          if $noweight
            if $environment == 0
              $outfh.puts '# %-3s %9d %9d %5.2f %8d %8.4f' % columns
            else
              $outfh.puts "# %-3s %-#{$env_features.size}s %9d %9d %8.4f" % columns
            end
          else
            if $environment == 0
              $outfh.puts '# %-3s %9.2f %9.2f %5.2f %8d %8.4f' % columns
            else
              $outfh.puts "# %-3s %-#{$env_features.size}s %9.2f %9.2f %8.4f" % columns
            end
          end
        end

        $outfh.puts '#'
        $outfh.puts '# RES: Amino acid one letter code'
        $outfh.puts '# ENV: Environment label of amino acid'
        $outfh.puts '# TOT_OBS: Total count of incidence'
        $outfh.puts '# MUT_OBS: Total count of mutation'

        if $environment == 0
          $outfh.puts '# MUTB: Mutability (MUT_OBS / TOT_OBS)'
          $outfh.puts '# REL_MUTB: Relative mutability (ALA = 100)'
        end

        $outfh.puts '# REL_FREQ: Relative frequency'
        $outfh.puts '#'

        #
        # Part 4. END
        #


        # Part 5.
        #
        # Generating substitution frequency matrices
        #

        # calculating probabilities for each environment class
        $env_classes.values.each do |e|
          if e.freq_array.sum != 0
            e.prob_array = 100.0 * e.freq_array / e.freq_array.sum
          end
        end

        # count raw frequencies
        $tot_cnt_mat    = NMatrix.float($amino_acids.size, $amino_acids.size)
        group_matrices  = []

        # for each combination of environment features
        $env_classes.groups_sorted_by_residue_labels.each_with_index do |group, group_no|
          grp_cnt_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

          $amino_acids.each_with_index do |aa, aj|
            freq_array = group[1].find { |e| e.label.start_with?(aa) }.freq_array
            0.upto($amino_acids.size - 1) { |i| grp_cnt_mat[aj, i] = freq_array[i] }
          end

          $tot_cnt_mat += grp_cnt_mat
          group_matrices << [group[0], grp_cnt_mat]
        end

        $logger.info "Counting substitutions done."

        if $output == 0
          heatmaps      = HeatmapArray.new if $heatmap == 1 or $heatmap == 2
          grp_max_val   = group_matrices.map { |l, m, n| m }.map { |m| m.max }.max
          aa_max_cnt    = $aa_tot_cnt.to_a.map { |k, v| v }.max
          mat_col_size  = aa_max_cnt.floor.to_s.size + 4
          $heatmapcol ||= Math::sqrt(group_matrices.size).round

          group_matrices.each_with_index do |(grp_label, grp_cnt_mat), grp_no|
            # for a matrix file
            stem = "#{grp_no}. #{grp_label}"
            $outfh.puts ">#{grp_label} #{grp_no}"
            $outfh.puts grp_cnt_mat.pretty_string(:col_header => $amino_acids,
                                                  :row_header => $amino_acids,
                                                  :col_size   => mat_col_size > 7 ? mat_col_size : 7)

            # for a heat map
            if $heatmap == 0 or $heatmap == 2
              grp_cnt_mat.heatmap(:col_header     => $amino_acids,
                                  :row_header     => $amino_acids,
                                  :rvg_width      => $rvg_width,
                                  :rvg_height     => $rvg_height,
                                  :canvas_width   => $canvas_width,
                                  :canvas_height  => $canvas_height,
                                  :max_val        => grp_max_val.ceil,
                                  :min_val        => 0,
                                  :print_value    => $heatmapvalues,
                                  :title          => stem).write("#{stem}.#{$heatmapformat}")

              $logger.info "Generating a heat map for #{stem} table done."
            end

            if $heatmap == 1 or $heatmap == 2
              title_font_size = $rvg_width * $heatmapcol / 80.0
              heatmaps << grp_cnt_mat.heatmap(:col_header       => $amino_acids,
                                              :row_header       => $amino_acids,
                                              :rvg_width        => $rvg_width,
                                              :rvg_height       => $rvg_height - 50,
                                              :canvas_width     => $canvas_width,
                                              :canvas_height    => $canvas_height - 50,
                                              :max_val          => grp_max_val.ceil,
                                              :min_val          => 0,
                                              :print_value      => $heatmapvalues,
                                              :print_gradient   => false,
                                              :title            => stem,
                                              :title_font_size  => $rvg_width * $heatmapcol / 100.0)
            end
          end

          if $heatmap == 1 or $heatmap == 2
            file = "#{$heatmapstem}.#{$heatmapformat}"
            heatmaps.heatmap(:columns   => $heatmapcol,
                             :rvg_width => $rvg_width,
                             :max_val   => grp_max_val.ceil,
                             :min_val   => 0).write(file)

            $logger.info "Generating heat maps in a file, #{file} done."
          end

          # total
          $outfh.puts '>Total'
          $outfh.puts $tot_cnt_mat.pretty_string(:col_header => $amino_acids,
                                                 :row_header => $amino_acids,
                                                 :col_size   => mat_col_size > 7 ? mat_col_size : 7)

          if $heatmap == 0 or $heatmap == 2
            stem    = "#{group_matrices.size}. TOTAL"
            heatmap = $tot_cnt_mat.heatmap(:col_header    => $amino_acids,
                                           :row_header    => $amino_acids,
                                           :rvg_width     => $rvg_width,
                                           :rvg_height    => $rvg_height,
                                           :canvas_width  => $canvas_width,
                                           :canvas_height => $canvas_height,
                                           :max_val       => $tot_cnt_mat.max.ceil,
                                           :min_val       => 0,
                                           :print_value   => $heatmapvalues,
                                           :title         => stem).write("#{stem}.#{$heatmapformat}")

            $logger.info "Generating a heat map for #{stem} table done."
          end
          exit 0
        end

        #
        # Part 5. END
        #


        # Part 6.
        #
        # Calculating substitution probability tables
        #

        if $output == 1
          $outfh.puts <<HEADER
#
# Each column (j) represents the probability distribution for the 
# likelihood of acceptance of a mutational event by a residue type j in 
# a particular structural environment (specified after >) leading to 
# any other residue type (i) and sums up to 100.
#
HEADER
        end

        # when nosmoothing !!!
        if ($output > 0) && $nosmooth
          $tot_cnt_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

          # if pseudo count provided, reinitialize $tot_cnt_mat by adding pseudocounts
          if $add
            $env_classes.values.each { |e| e.freq_array += $add }
          end

          # re-calculate probability vector for each environment class
          $env_classes.values.each do |e|
            if e.freq_array.sum == 0
              # if no observation, then probabilities are zeros, too
              e.prob_array = e.freq_array
            else
              e.prob_array = 100.0 * e.freq_array / e.freq_array.sum.to_f
            end
          end

          group_matrices = []

          $env_classes.groups_sorted_by_residue_labels.each_with_index do |group, group_no|
            grp_cnt_mat   = NMatrix.float($amino_acids.size, $amino_acids.size)
            grp_prob_mat  = NMatrix.float($amino_acids.size, $amino_acids.size)

            $amino_acids.each_with_index do |aa, aj|
              env_class = group[1].find { |e| e.label.start_with?(aa) }
              0.upto($amino_acids.size - 1) { |i| grp_cnt_mat[aj, i] = env_class.freq_array[i] }
              0.upto($amino_acids.size - 1) { |i| grp_prob_mat[aj, i] = env_class.prob_array[i] }
            end

            $tot_cnt_mat += grp_cnt_mat
            group_matrices << [group[0], grp_prob_mat]
          end

          if $output == 1
            heatmaps      = HeatmapArray.new if $heatmap == 1 or $heatmap == 2
            grp_max_val   = group_matrices.map { |l, m, n| m }.map { |m| m.max }.max || 100
            $heatmapcol ||= Math::sqrt(group_matrices.size).round

            group_matrices.each_with_index do |(grp_label, grp_prob_mat), grp_no|
              # for a matrix file
              stem = "#{grp_no}. #{grp_label}"
              $outfh.puts ">#{grp_label} #{grp_no}"
              $outfh.puts grp_prob_mat.pretty_string(:col_header => $amino_acids,
                                                     :row_header => $amino_acids)

              # for a heat map
              if $heatmap == 0 or $heatmap == 2
                grp_prob_mat.heatmap(:col_header    => $amino_acids,
                                     :row_header    => $amino_acids,
                                     :rvg_width     => $rvg_width,
                                     :rvg_height    => $rvg_height,
                                     :canvas_width  => $canvas_width,
                                     :canvas_height => $canvas_height,
                                     :max_val       => grp_max_val.ceil,
                                     :min_val       => 0,
                                     :print_value   => $heatmapvalues,
                                     :title         => stem).write("#{stem}.#{$heatmapformat}")

                $logger.info "Generating a heat map for #{stem} table done."
              end

              if $heatmap == 1 or $heatmap == 2
                title_font_size = $rvg_width * $heatmapcol / 80.0
                heatmaps << grp_prob_mat.heatmap(:col_header      => $amino_acids,
                                                 :row_header      => $amino_acids,
                                                 :rvg_width       => $rvg_width,
                                                 :rvg_height      => $rvg_height - 50,
                                                 :canvas_width    => $canvas_width,
                                                 :canvas_height   => $canvas_height - 50,
                                                 :max_val         => grp_max_val.ceil,
                                                 :min_val         => 0,
                                                 :print_value     => $heatmapvalues,
                                                 :print_gradient  => false,
                                                 :title           => stem,
                                                 :title_font_size => title_font_size)
              end
            end

            # for heat maps in a single file
            if $heatmap == 1 or $heatmap == 2
              file = "#{$heatmapstem}.#{$heatmapformat}"
              heatmaps.heatmap(:columns   => $heatmapcol,
                               :rvg_width => $rvg_width,
                               :max_val   => grp_max_val.ceil,
                               :min_val   => 0).write(file)

              $logger.info "Generating heat maps in a file, #{file} done."
            end
          end

          $tot_prob_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

          0.upto($amino_acids.size - 1) do |aj|
            col_sum = (0..$amino_acids.size - 1).inject(0) { |s, i| s + $tot_cnt_mat[aj, i] }
            0.upto($amino_acids.size - 1) { |i| $tot_prob_mat[aj, i] = 100.0 * $tot_cnt_mat[aj, i] / col_sum }
          end

          if $output == 1
            $outfh.puts '>Total'
            $outfh.puts $tot_prob_mat.pretty_string(:col_header => $amino_acids,
                                                    :row_header => $amino_acids)
            $outfh.close

            # for a heat map
            if $heatmap == 0 or $heatmap == 2
              stem = "#{group_matrices.size}. TOTAL"
              $tot_prob_mat.heatmap(:col_header     => $amino_acids,
                                    :row_header     => $amino_acids,
                                    :rvg_width      => $rvg_width,
                                    :rvg_height     => $rvg_height,
                                    :canvas_width   => $canvas_width,
                                    :canvas_height  => $canvas_height,
                                    :max_val        => $tot_prob_mat.max.ceil,
                                    :min_val        => 0,
                                    :print_value    => $heatmapvalues,
                                    :title          => stem).write("#{stem}.#{$heatmapformat}")

              $logger.info "Generating a heat map for #{stem} table done."
            end
            exit 0
          end

          $logger.info 'Calculating substitution probabilities (no smoothing) done.'
        end

        # when smoothing!!!
        if ($output > 0) && !$nosmooth
          #
          # p1 probabilities
          #
          p1      = NArray.float($amino_acids.size)
          a0      = NArray.float($amino_acids.size).fill(1.0 / $amino_acids.size)
          big_N   = $tot_aa.to_f
          small_n = $amino_acids.size.to_f
          omega1  = 1.0 / (1 + big_N / ($sigma * small_n))
          omega2  = 1.0 - omega1

          if ($smooth == :full) || $p1smooth
            # smoothing p1 probabilities for the partial smoothing procedure if --p1smooth on or, if it is full smoothing
            0.upto($amino_acids.size - 1) do |i|
              if $environment == 0
                p1[i] = 100.0 * (omega1 * a0[i] + omega2 * $aa_tot_freq[$amino_acids[i]])
              else
                p1[i] = 100.0 * (omega1 * a0[i] + omega2 * $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[i]) }.map { |k, v| v }.sum)
              end
            end
            $smooth_prob[1] = p1
          elsif ($smooth == :partial)
            # no smoothing for p1 probabilities just as Kenji's subst
            # in this case, p1 probabilities were taken from the amino acid frequencies of your data set
            0.upto($amino_acids.size - 1) do |i|
              if $environment == 0
                p1[i] = 100.0 * $aa_tot_freq[$amino_acids[i]]
              else
                p1[i] = 100.0 * $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[i]) }.map { |k, v| v }.sum
              end
            end
            $smooth_prob[1] = p1
          end

          #
          # p2 and above
          #
          env_labels = $env_features.map_with_index { |ef, ei| ef.labels.map { |l| "#{ei}#{l}" } }

          if $environment == 1
            env_labels += $env_features[1..-1].map_with_index { |ef, ei| ef.labels.map { |l| "#{ei + $env_features.size}#{l}" } }
          end

          if $smooth == :partial
            $outfh.puts <<HEADER
#
# Partial Smoothing:
#
HEADER
            if $p1smooth
              $outfh.puts <<HEADER
# p1(ri) (i.e., amino acid composition) is estimated by summing over
# each row in all matrices and smoothing them with A0 (a uniform distribution)
#                              ^^^^^^^^^
HEADER
            else
              $outfh.puts <<HEADER
# p1(ri) (i.e., amino acid composition) is estimated by summing over
# each row in all matrices without smoothing
#                          ^^^^^^^^^^^^^^^^^
HEADER
            end

            $outfh.puts <<HEADER
# p2(ri|Rj) is estimated as:
#    p2(ri|Rj) = omega1 * p1(ri) + omega2 * W2(ri|Rj)
# 
# p3(ri|Rj,fq) is estimated as:
#    p3(ri|Rj,fq) = omega1 * A2(ri|fq) + omega2 * W3(ri|Rj,fq)
# where
#    A2(ri|fq) = p2(ri|fq) (fixed fq to be Rj; partial smoothing)
# 
# The smoothing procedure is curtailed here and finally
#                            ^^^^^^^^^
# p5(ri|Rj,...) is estimated as:
#    p5(ri|Rj,...) = omega1 * A3(ri|Rj,fq) + omega2 * W5(ri|Rj...)
# where
#    A3(ri|Rj,fq) = sum over fq omega_c * pc3(Rj,fq)
# 
# Weights (omegas) are calculated as in Topham et al. (1993)
# 
# sigma value used is:  #{$sigma}
#
HEADER
            1.upto(env_labels.size) do |ci|
              # for partial smoothing, only P1 ~ P3, and Pn are considered
              if (ci > 2) && (ci < env_labels.size)
                $logger.debug "Skipped the level #{ci + 1} probabilities, due to partial smoothing."
                next
              end

              env_labels.combination(ci) do |c1|
                c1[0].product(*c1[1..-1]).each do |labels|
                  pattern = '.' * $env_features.size

                  if $environment == 1
                    pattern += '.' * ($env_features.size - 1)
                  end

                  labels.each do |label|
                    i = label[0].chr.to_i
                    l = label[1].chr
                    pattern[i] = l
                  end

                  if pattern =~ /^\./
                    $logger.debug "Skipped the environment class, #{pattern}, due to partial smoothing."
                    next
                  end

                  if $environment == 1
                    pattern[$env_features.size, 0] = "-"
                  end

                  # get environments matching the pattern created above
                  # and calculate amino acid frequencies and their probabilities for all the environments
                  envs      = $env_classes.values.select { |env| env.label.match(/^#{pattern}/) }
                  freq_arr  = envs.inject(NArray.float($amino_acids.size)) { |sum, env| sum + env.freq_array }
                  prob_arr  = NArray.float($amino_acids.size)
                  0.upto($amino_acids.size - 1) do |i|
                    if freq_arr.sum == 0
                      prob_arr[i] = 0
                    else
                      prob_arr[i] = freq_arr[i] / freq_arr.sum.to_f
                    end
                  end

#                  # assess whether a residue type j is compatible with a particular combination of structural features
#                  # corrections for non-zero colum vector phenomenon by switching the smoothing procedure off as below
#                  if ci == $env_features.size
#                    aa_label        = labels.find { |l| l.match(/^0/) }[1].chr
#                    sub_pattern     = '.' * $env_features.size
#                    sub_pattern[0]  = aa_label
#                    sub_freq_sum    = 0
#
#                    labels[1..-1].each do |label|
#                      next if label.start_with?('0')
#                      i               = label[0].chr.to_i
#                      l               = label[1].chr
#                      sub_pattern[i]  = l
#                      sub_envs        = $env_classes.values.select { |env| env.label.match(pattern.to_re) }
#                      sub_freq_arr    = sub_envs.inject(NArray.float($amino_acids.size)) { |sum, env| sum + env.freq_array }
#                      sub_freq_sum    += sub_freq_arr.sum
#                    end
#
#                    if sub_freq_sum == 0
#                      if $smooth_prob.has_key?(ci + 1)
#                        $smooth_prob[ci + 1][labels.to_set] = prob_arr
#                      else
#                        $smooth_prob[ci + 1] = {}
#                        $smooth_prob[ci + 1][labels.to_set] = prob_arr
#                      end
#                      $logger.warn "Smoothing procedure is off for the environment feature combination, #{pattern}"
#                      next
#                    end
#                  end

                  # collect priors
                  priors = []

                  if ci == 1
                    priors << $smooth_prob[1]
                  elsif ci == 2
                    labels.combination(1).select { |c2| c2[0].start_with?('0') }.each do |c3|
                      priors << $smooth_prob[2][c3.to_set]
                    end
                  elsif ci == env_labels.size
                    labels.combination(2).select { |c2| c2[0].start_with?('0') || c2[1].start_with?('0') }.each do |c3|
                      priors << $smooth_prob[3][c3.to_set]
                    end
                  end

                  # entropy based weighting prior step
                  entropy_max     = NMath::log($amino_acids.size)
                  entropies       = priors.map { |prior| -1.0 * prior.to_a.inject(0.0) { |s, p| p == 0 ? s : s + p * Math::log(p) } }
                  mod_entropies   = entropies.map { |entropy| (entropy_max - entropy) / entropy_max }
                  weights         = mod_entropies.map { |mod_entropy| mod_entropy / mod_entropies.sum }
                  weighted_priors = priors.map_with_index { |prior, i| prior * weights[i] }.sum

                  # actual smoothing step
                  smooth_prob_arr = NArray.float($amino_acids.size)
                  big_N           = freq_arr.sum.to_f
                  small_n         = $amino_acids.size.to_f
                  omega1          = 1.0 / (1 + big_N / ($sigma * small_n))
                  omega2          = 1.0 - omega1
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (omega1 * weighted_priors[i] + omega2 * prob_arr[i]) }

                  # normalization step
                  total = smooth_prob_arr.sum
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (smooth_prob_arr[i] / total) }

                  # store smoothed probabilties in a hash using a set of envrionment labels as a key
                  if $smooth_prob.has_key?(ci + 1)
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  else
                    $smooth_prob[ci + 1] = {}
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  end
                end
              end
            end
            $logger.info 'Calculating substitution probabilities (partial smoothing) done.'
          else
            $outfh.puts <<HEADER
#
# Full Smoothing:
#
# p1(ri) is estimated as:
#     p1(ri) = omega1 * A0 + omega2 * W1(ri)
#
# p2(ri|f1q) is estimated as:
#     p2(ri|f1q) = omega1 * p1(ri) + omega2 * W2(ri|fq)
#
#     (NOTE: f1q is not fixed to be Rj in the full smoothing procedure)
# 
# p3(ri|f1q,f2q) is estimated as:
#    p3(ri|f1q,f2q) = omega1 * A2(ri|f1q) + omega2 * W3(ri|f1q,f2q)
# where
#    A2(ri|fq) = p2(ri|fq) (not fixed fq; full smoothing)
# 
# The smoothing procedure is NOT curtailed here and it goes upto
#                            ^^^^^^^^^^^^^
#
# pn(ri|f1q,f2q,...,fn-1q) is estimated as:
#    pn(ri|f1q,f2q,...,fn-1q) = omega1 * An-1(ri|f1q, f2q,...,fn-2q) + omega2 * Wn(ri|f1q,f2q,...,fn-1q)
# where
#    An-1(ri|f1q,f2q,...,fn-2q) = sum over fq omega_c * pcn-1(f1q,f2q,...,fn-2q)
# 
# Weights (omegas) are calculated as in Topham et al. (1993)
# 
# sigma value used is:  #{$sigma}
#
HEADER
            # full smooting
            1.upto(env_labels.size) do |ci|
              env_labels.combination(ci) do |c1|
                c1[0].product(*c1[1..-1]).each do |labels|

                  pattern = '.' * $env_features.size

                  if $environment == 1
                    pattern += '.' * ($env_features.size - 1)
                  end

                  labels.each do |label|
                    j = label[0].chr.to_i
                    l = label[1].chr
                    pattern[j] = l
                  end

                  if $environment == 1
                    pattern[$env_features.size, 0] = "-"
                  end

                  # get environmetns, frequencies, and probabilities
                  envs      = $env_classes.values.select { |env| env.label.match(/^#{pattern}/) }
                  freq_arr  = envs.inject(NArray.float($amino_acids.size)) { |sum, env| sum + env.freq_array }
                  prob_arr  = NArray.float($amino_acids.size)
                  0.upto($amino_acids.size - 1) { |i| prob_arr[i] = freq_arr[i] == 0 ? 0 : freq_arr[i] / freq_arr.sum.to_f }

                  # collect priors
                  priors = []

                  if ci > 1
                    labels.combination(ci - 1).each { |c2| priors << $smooth_prob[ci][c2.to_set] }
                  else
                    priors << $smooth_prob[1]
                  end

                  # entropy based weighting priors step
                  entropy_max     = NMath::log($amino_acids.size)
                  entropies       = priors.map { |prior| -1.0 * prior.to_a.inject(0.0) { |s, p| p == 0 ? s : s + p * Math::log(p) } }
                  mod_entropies   = entropies.map_with_index { |entropy, i| (entropy_max - entropies[i]) / entropy_max }
                  weights         = mod_entropies.map { |mod_entropy| mod_entropy / mod_entropies.sum }
                  weighted_priors = priors.map_with_index { |prior, i| prior * weights[i] }.sum

                  # smoothing step
                  smooth_prob_arr = NArray.float($amino_acids.size)
                  big_N           = freq_arr.sum.to_f
                  small_n         = $amino_acids.size.to_f
                  omega1          = 1.0 / (1 + big_N / ($sigma * small_n))
                  omega2          = 1.0 - omega1
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (omega1 * weighted_priors[i] + omega2 * prob_arr[i]) }

                  # normalization step
                  total = smooth_prob_arr.sum
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (smooth_prob_arr[i] / total) }

                  # store smoothed probabilties in a hash using a set of envrionment labels as a key
                  if $smooth_prob.has_key?(ci + 1)
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  else
                    $smooth_prob[ci + 1] = {}
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  end
                end
              end
            end
            $logger.info 'Calculating substitution probabilities (full smoothing) done.'
          end

          # updating smoothed probability array for each envrionment
          $env_classes.values.each do |env|
            env.smooth_prob_array = $smooth_prob[env_labels.size + 1][env.label_set]
          end

          # sorting environments and build 21X21 substitution matrices
          group_matrices = []

          $env_classes.groups_sorted_by_residue_labels.each do |group|
            # calculating 21X21 substitution probability matrix for each envrionment
            grp_prob_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

            $amino_acids.each_with_index do |aa, ai|
              smooth_prob_arr = group[1].find { |e| e.label.start_with?(aa) }.smooth_prob_array
              0.upto($amino_acids.size - 1) { |j| grp_prob_mat[ai, j] = smooth_prob_arr[j] }
            end

            group_matrices << [group[0], grp_prob_mat]
          end

          if $output == 1
            heatmaps      = HeatmapArray.new if $heatmap == 1 or $heatmap == 2
            grp_max_val   = group_matrices.map { |l, m, n| m }.map { |m| m.max }.max || 100
            $heatmapcol ||= Math::sqrt(group_matrices.size).round

            group_matrices.each_with_index do |(grp_label, grp_prob_mat), grp_no|
              # for a matrix file
              stem = "#{grp_no}. #{grp_label}"
              $outfh.puts ">#{grp_label} #{grp_no}"
              $outfh.puts grp_prob_mat.pretty_string(:col_header => $amino_acids,
                                                     :row_header => $amino_acids)

              # for heat map generation
              if $heatmap == 0 or $heatmap == 2
                grp_prob_mat.heatmap(:col_header    => $amino_acids,
                                     :row_header    => $amino_acids,
                                     :rvg_width     => $rvg_width,
                                     :rvg_height    => $rvg_height,
                                     :canvas_width  => $canvas_width,
                                     :canvas_height => $canvas_height,
                                     :max_val       => grp_max_val.ceil,
                                     :min_val       => 0,
                                     :print_value   => $heatmapvalues,
                                     :title         => stem).write("#{stem}.#{$heatmapformat}")

                $logger.info "Generating a heat map for #{stem} table done."
              end

              if $heatmap == 1 or $heatmap == 2
                title_font_size = $rvg_width * $heatmapcol / 80.0
                heatmaps << grp_prob_mat.heatmap(:col_header      => $amino_acids,
                                                 :row_header      => $amino_acids,
                                                 :rvg_width       => $rvg_width,
                                                 :rvg_height      => $rvg_height - 50,
                                                 :canvas_width    => $canvas_width,
                                                 :canvas_height   => $canvas_height - 50,
                                                 :max_val         => grp_max_val.ceil,
                                                 :min_val         => 0,
                                                 :print_value     => $heatmapvalues,
                                                 :print_gradient  => false,
                                                 :title           => stem,
                                                 :title_font_size => title_font_size)
              end
            end

            # for heat maps in a single file
            if $heatmap == 1 or $heatmap == 2
              file = "#{$heatmapstem}.#{$heatmapformat}"
              heatmaps.heatmap(:columns   => $heatmapcol,
                               :rvg_width => $rvg_width,
                               :max_val   => grp_max_val.ceil,
                               :min_val   => 0).write(file)

              $logger.info "Generating heat maps in a file, #{file} done."
            end
          end

          # for a total substitution probability matrix
          $tot_prob_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

          $amino_acids.each_with_index do |aa, aj|
            0.upto($amino_acids.size - 1) do |ai|
              $tot_prob_mat[aj, ai] = $smooth_prob[2][["0#{aa}"].to_set][ai]
            end
          end

          if $output == 1
            $outfh.puts '>Total'
            $outfh.puts $tot_prob_mat.pretty_string(:col_header => $amino_acids,
                                                    :row_header => $amino_acids)
            $outfh.close

            # for a heat map
            if $heatmap == 0 or $heatmap == 2
              stem = "#{group_matrices.size}. TOTAL"
              $tot_prob_mat.heatmap(:col_header     => $amino_acids,
                                    :row_header     => $amino_acids,
                                    :rvg_width      => $rvg_width,
                                    :rvg_height     => $rvg_height,
                                    :canvas_width   => $canvas_width,
                                    :canvas_height  => $canvas_height,
                                    :max_val        => $tot_prob_mat.max.ceil,
                                    :min_val        => 0,
                                    :print_value    => $heatmapvalues,
                                    :title          => stem).write("#{stem}.#{$heatmapformat}")

              $logger.info "Generating a heat map for #{stem} table done."
            end
            exit 0
          end
        end

        #
        # Part 6. END
        #


        # Part 7.
        #
        # Calculating log odds ratio scoring matrices
        #
        if $output == 2
          $outfh.puts <<HEADER
# 
# The probabilities were then divided by the background probabilities
HEADER
          if $penv
            $outfh.puts <<HEADER
# which were derived from the environment-dependent amino acid frequencies.
#                             ^^^^^^^^^^^^^^^^^^^^^
HEADER
          else
            $outfh.puts <<HEADER
# which were derived from the environment-independent amino acid frequencies.
#                             ^^^^^^^^^^^^^^^^^^^^^^^
HEADER
          end

          grp_logo_mats = []
          factor        = $scale / NMath::log(2)

          $env_classes.groups_sorted_by_residue_labels.each_with_index do |group, group_no|
            # calculating substitution probability matrix for each envrionment
            grp_label     = group[0]
            grp_envs      = group[1]
            grp_logo_mat  = $cys == 0 ?
                            NMatrix.float($amino_acids.size, $amino_acids.size + 1) :
                            NMatrix.float($amino_acids.size, $amino_acids.size)

            if $environment == 1
              # parse substituting aa's environment label
              tgt_label = grp_label.split('-').last
            end

            $amino_acids.each_with_index do |aa, aj|
              env             = grp_envs.detect { |e| e.label.start_with?(aa) }
              env.logo_array  = $cys == 0 ?
                                NArray.float($amino_acids.size + 1) :
                                NArray.float($amino_acids.size)

              env.send($nosmooth ? 'prob_array' : 'smooth_prob_array').to_a.each_with_index do |prob, ai|
                if $environment == 0
                  pai = 100.0 * $aa_tot_freq[$amino_acids[ai]]
                else
                  pai = 100.0 * $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[ai]) }.map { |k, v| v }.sum
                end

                odds                  = prob / pai
                env.logo_array[ai]    = factor * NMath::log(odds)
                grp_logo_mat[aj, ai]  = env.logo_array[ai]
              end

              # adding log odds ratio for 'U' (J or C) when --cyc is 0
              if $cys == 0
                if $environment == 0
                  pai = 100.0 * ($aa_tot_freq['C'] + $aa_tot_freq['J'])
                else
                  pai = 100.0 * ($aa_tot_freq.select { |k, v| k.start_with?('C') }.map { |k, v| v }.sum +
                                 $aa_tot_freq.select { |k, v| k.start_with?('J') }.map { |k, v| v }.sum)
                end
                prob  = env.send($nosmooth ? 'prob_array' : 'smooth_prob_array')[$amino_acids.index('C')] +
                        env.send($nosmooth ? 'prob_array' : 'smooth_prob_array')[$amino_acids.index('J')]
                odds  = prob / pai
                env.logo_array[$amino_acids.size]   = factor * NMath::log(odds)
                grp_logo_mat[aj, $amino_acids.size] = env.logo_array[$amino_acids.size]
              end
            end

            grp_logo_mats << [grp_label, grp_logo_mat]
          end

          $tot_logo_mat = $cys == 0 ?
                          NMatrix.float($amino_acids.size, $amino_acids.size + 1) :
                          NMatrix.float($amino_acids.size, $amino_acids.size)

          $amino_acids.each_with_index do |aa1, aj|
            $amino_acids.each_with_index do |aa2, ai|
              prob = $tot_prob_mat[aj, ai]

              if $environment == 0
                pai = 100.0 * $aa_tot_freq[$amino_acids[ai]]
              else
                pai = 100.0 * $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[ai]) }.map { |k, v| v }.sum
              end

              odds = prob / pai
              $tot_logo_mat[aj, ai] = factor * NMath::log(odds)
            end

            # adding log odds ratio for 'U' (J or C) when --cyc is 0
            if $cys == 0
              if $environment == 0
                pai = 100.0 * ($aa_tot_freq['C'] + $aa_tot_freq['J'])
              else
                pai = 100.0 * ($aa_tot_freq.select { |k, v| k.start_with?('C') }.map { |k, v| v }.sum +
                               $aa_tot_freq.select { |k, v| k.start_with?('J') }.map { |k, v| v }.sum)
              end
              prob  = $tot_prob_mat[aj, $amino_acids.index('C')] + $tot_prob_mat[aj, $amino_acids.index('J')]
              odds  = prob / pai
              $tot_logo_mat[aj, $amino_acids.size] = factor * NMath::log(odds)
            end
          end

          # calculating relative entropy for each amino acid pair H and
          # the expected score E in bit units
          tot_E = 0.0
          tot_H = 0.0

          0.upto($tot_logo_mat.shape[0] - 1) do |j|
            0.upto($tot_logo_mat.shape[0] - 1) do |i| # it's deliberately '0' not '1'
              if j != i
                if $environment == 0
                  tot_E += $tot_logo_mat[j, i] * $aa_tot_freq[$amino_acids[j]] * $aa_tot_freq[$amino_acids[i]] / 2.0
                else
                  tot_E +=  $tot_logo_mat[j, i] *
                            $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[j]) }.map { |k, v| v }.sum *
                            $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[i]) }.map { |k, v| v }.sum / 2.0
                end
                tot_H += $tot_logo_mat[j, i] * $tot_prob_mat[j, i] / 2.0 / 10000.0
              else
                if $environment == 0
                  tot_E += $tot_logo_mat[j, i] * $aa_tot_freq[$amino_acids[i]] * $aa_tot_freq[$amino_acids[i]]
                else
                  tot_E +=  $tot_logo_mat[j, i] *
                            $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[j]) }.map { |k, v| v }.sum *
                            $aa_tot_freq.select { |k, v| k.start_with?($amino_acids[i]) }.map { |k, v| v }.sum
                end
                tot_H += $tot_logo_mat[j, i] * $tot_prob_mat[j, i] / 10000.0
              end
            end
          end

          $outfh.puts <<HEADER
# 
# Shown here are logarithms of these values multiplied by #{$scale}/log(2) 
HEADER
          unless $noroundoff
            $outfh.puts <<HEADER
# rounded to the nearest integer (log-odds scores in 1/#{$scale} bit units).
HEADER
          end

          $outfh.puts <<HEADER
# For total (composite) matrix, Entropy = #{"%5.4f" % tot_H} bits, Expected score = #{"%5.4f" % tot_E}
#
HEADER

          grp_max_val = grp_logo_mats.map { |l, m| m }.map { |m| m.max }.max
          grp_min_val = grp_logo_mats.map { |l, m| m }.map { |m| m.min }.min
          abs_max_val = [grp_max_val.abs, grp_min_val.abs].max
          row_header  = $cys ? $amino_acids + %w[U] : $amino_acids
          heatmaps    = HeatmapArray.new if $heatmap == 1 or $heatmap == 2
          $heatmapcol ||= Math::sqrt(grp_logo_mats.size).round

          grp_logo_mats.each_with_index do |arr, grp_no|
            grp_label     = arr[0]
            grp_logo_mat  = arr[1]
            stem          = "#{grp_no}. #{grp_label}"

            unless $noroundoff
              grp_logo_mat = grp_logo_mat.round
            end

            # for a matrix file
            $outfh.puts ">#{grp_label} #{grp_no}"
            $outfh.puts grp_logo_mat.pretty_string(:col_header => $amino_acids,
                                                   :row_header => row_header)
            # for a heat map
            if $heatmap == 0 or $heatmap == 2
              grp_logo_mat.heatmap(:col_header          => $amino_acids,
                                   :row_header          => row_header,
                                   :rvg_width           => $rvg_width,
                                   :rvg_height          => $rvg_height,
                                   :canvas_width        => $canvas_width,
                                   :canvas_height       => $canvas_height,
                                   :gradient_beg_color  => '#0000FF',
                                   :gradient_mid_color  => '#FFFFFF',
                                   :gradient_end_color  => '#FF0000',
                                   :max_val             => abs_max_val.ceil,
                                   :mid_val             => 0,
                                   :min_val             => -1 * abs_max_val.ceil,
                                   :print_value         => $heatmapvalues,
                                   :title               => stem).write("#{stem}.#{$heatmapformat}")

              $logger.info "Generating a heat map for #{stem} table done."
            end

            if $heatmap == 1 or $heatmap == 2
              title_font_size = $rvg_width * $heatmapcol / 80.0
              heatmaps << grp_logo_mat.heatmap(:col_header          => $amino_acids,
                                               :row_header          => row_header,
                                               :rvg_width           => $rvg_width,
                                               :rvg_height          => $rvg_height,
                                               :canvas_width        => $canvas_width,
                                               :canvas_height       => $canvas_height,
                                               :gradient_beg_color  => '#0000FF',
                                               :gradient_mid_color  => '#FFFFFF',
                                               :gradient_end_color  => '#FF0000',
                                               :max_val             => abs_max_val.ceil,
                                               :mid_val             => 0,
                                               :min_val             => -1 * abs_max_val.ceil,
                                               :print_value         => $heatmapvalues,
                                               :print_gradient      => false,
                                               :title               => stem,
                                               :title_font_scale    => 1.0,
                                               :title_font_size     => title_font_size)
            end
          end

          # for heat maps in a single file
          if $heatmap == 1 or $heatmap == 2
            file = "#{$heatmapstem}.#{$heatmapformat}"
            heatmaps.heatmap(:columns             => $heatmapcol,
                             :rvg_width           => $rvg_width,
                             :gradient_beg_color  => '#0000FF',
                             :gradient_mid_color  => '#FFFFFF',
                             :gradient_end_color  => '#FF0000',
                             :max_val             => abs_max_val.ceil,
                             :mid_val             => 0,
                             :min_val             => -1 * abs_max_val.ceil).write(file)

            $logger.info "Generating heat maps in a file, #{file} done."
          end

          # for a matrix file
          unless $noroundoff
            $tot_logo_mat = $tot_logo_mat.round
          end

          $outfh.puts ">Total #{grp_logo_mats.size}"
          $outfh.puts $tot_logo_mat.pretty_string(:col_header => $amino_acids,
                                                  :row_header => row_header)

          # for a heat map
          if $heatmap == 0 or $heatmap == 2
            stem            = "#{group_matrices.size}. TOTAL"
            tot_abs_max_val = [$tot_logo_mat.max.abs, $tot_logo_mat.min.abs].max
            $tot_logo_mat.heatmap(:col_header          => $amino_acids,
                                  :row_header          => row_header,
                                  :rvg_width           => $rvg_width,
                                  :rvg_height          => $rvg_height,
                                  :canvas_width        => $canvas_width,
                                  :canvas_height       => $canvas_height,
                                  :gradient_beg_color  => '#0000FF',
                                  :gradient_mid_color  => '#FFFFFF',
                                  :gradient_end_color  => '#FF0000',
                                  :max_val             => tot_abs_max_val.ceil,
                                  :mid_val             => 0,
                                  :min_val             => -1 * tot_abs_max_val.ceil,
                                  :print_value         => $heatmapvalues,
                                  :title               => stem).write("#{stem}.#{$heatmapformat}")

            $logger.info "Generating a heat map for #{stem} table done."
          end

          $logger.info "Calculating log odds ratios done."
        end

        #
        # Part 7. END
        #

        $outfh.close
        exit 0
      end
    end

  end # class CLI
end # module Ulla
