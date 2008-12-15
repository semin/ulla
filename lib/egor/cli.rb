require "getoptlong"
require "logger"
require "rubygems"
require "narray"
require "bio"
require "set"
require "facets"
require "simple_memoize"

require "narray_extensions"
require "nmatrix_extensions"
require "enumerable_extensions"
require "math_extensions"
require "environment_feature"
require "environment"

# This is a module for an actual command line interpreter for Egor
# ---
# Copyright (C) 2008-9 Semin Lee
module Egor
  class CLI
    class << self

      # :nodoc:
      def print_version
        puts Egor::VERSION
      end

      # Print Egor's Usage on the screen
      #
      # :call-seq:
      #   Egor::CLI::print_usage
      #
      def print_usage
        puts <<-USAGE
egor: Esst GeneratOR, a program to calculate environment-specific amino acid substitution tables.

Usage:
    egor [ options ] -l TEMLIST-file -c CLASSDEF-file
        or
    egor [ options ] -f TEM-file -c CLASSDEF-file

Options:
    --tem-file (-f) FILE: a tem file
    --tem-list (-l) FILE: a list for tem files
    --classdef (-c) FILE: a file for the defintion of environments (default: 'classdef.dat')
    --outfile (-o) FILE: output filename (default 'allmat.dat')
    --weight (-w) INTEGER: clustering level (PID) for the BLOSUM-like weighting
    --noweight: calculate substitution counts with no weights (default)
    --smooth (-s) INTEGER:
        0 for partial smoothing (default)
        1 for full smoothing
    --nosmooth: perform no smoothing operation
    --cys (-y) INTEGER:
        0 for using C and J only for structure (default)
        1 for both structure and sequence
        2 for using only C for both (should be set having no 'disulphide bonds' environment feature)
    --output INTEGER:
        0 for raw counts (no-smoothing performed)
        1 for probabilities
        2 for log-odds (default)
    --scale INTEGER: log-odds matrices in 1/n bit units (default 3)
    --sigma DOUBLE: change the sigma value for smoothing (default 5)
    --add DOUBLE: add this value to raw counts when deriving log-odds without smoothing (default 1/#classes)
    --penv: use environment-dependent frequencies for log-odds calculation (default false) (NOT implemented yet!!!)
    --pidmin DOUBLE: count substitutions only for pairs with PID equal to or greater than this value (default none)
    --pidmax DOUBLE: count substitutions only for pairs with PID smaller than this value (default none)
    --verbose (-v) INTEGER
        0 for ERROR level (default)
        1 for WARN or above level
        2 for INFO or above level
        3 for DEBUG or above level
    --version: print version
    --help (-h): show help

        USAGE
      end

      # Calculate PID between two sequences
      #
      # :call-seq:
      #   Egor::CLI::calc_pid(seq1, seq2)   -> Float
      #
      def calc_pid(seq1, seq2)
        s1    = seq1.split("")
        s2    = seq2.split("")
        cols  = s1.zip(s2)
        align = 0
        ident = 0
        intgp = 0

        cols.each do |col|
          if (col[0] != "-") && (col[1] != "-")
            align += 1
            if col[0] == col[1]
              ident += 1
            end
          elsif (((col[0] == "-") && (col[1] != "-")) ||
                 ((col[0] != "-") && (col[1] == "-")))
            intgp += 1
          end
        end

        pid = 100.0 * ident.to_f / (align + intgp)
      end
      memoize :calc_pid

      # :nodoc:
      def execute(arguments=[])
        #
        # Abbreviations in the aa1 codes
        #
        # * env: environment
        # * tem: (FUGUE) template
        # * classdef: (envlironment) class definition
        # * aa: amino acid
        # * aa: weighted amino acid
        # * tot: total
        # * rel: relative
        # * obs: observation (frequency)
        # * mut: mutation
        # * mutb: mutability
        # * freq: frequency
        # * prob: probability
        # * opts: options
        #

        # Part 1.
        #
        # Global variables and their default values
        #
        $logger       = Logger.new(STDOUT)
        $logger.level = Logger::ERROR
        $amino_acids  = "ACDEFGHIKLMNPQRSTVWYJ".split("")
        $tem_list     = nil
        $tem_file     = nil
        $classdef     = "classdef.dat"
        $outfile      = "allmat.dat"
        $outfh        = nil # file hanfle for outfile
        $output       = 2
        $ali_size     = 0
        $tot_aa       = 0
        $sigma        = 5.0
        $weight       = 60
        $noweight     = false
        $smooth       = :partial
        $nosmooth     = false
        $scale        = 3
        $pidmin       = nil
        $pidmax       = nil
        $scale        = 3
        $add          = nil
        $cys          = 0
        $penv         = false

        $aa_tot_obs   = Hash.new(0)
        $aa_mut_obs   = Hash.new(0)
        $aa_mutb      = {}
        $aa_rel_mutb  = {}
        $aa_rel_freq  = {}
        $env_aa_obs   = Hash.new(0)
        $smooth_prob  = {}
        $tot_freq_mat = nil
        $tot_prob_mat = nil
        $tot_logo_mat = nil

        # Part 2.
        #
        # Parsing options
        #
        opts = GetoptLong.new(
          [ '--help',     '-h', GetoptLong::NO_ARGUMENT ],
          [ '--tem-list', '-l', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--tem-file', '-f', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--classdef', '-c', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--smooth',   '-s', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--weight',   '-w', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--noweight',       GetoptLong::NO_ARGUMENT ],
          [ '--heatmap',        GetoptLong::NO_ARGUMENT ],
          [ '--output',         GetoptLong::REQUIRED_ARGUMENT ],
          [ '--cys',      '-y', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--penv',           GetoptLong::NO_ARGUMENT ],
          [ '--outfile',  '-o', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--verbose',  '-v', GetoptLong::REQUIRED_ARGUMENT ],
          [ '--version',        GetoptLong::NO_ARGUMENT ]
        )

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
          when '--output'
            $output       = arg.to_i
          when '--outfile'
            $outfile      = arg
          when '--cys'
            $cys          = arg.to_i
          when '--weight'
            $weight       = arg.to_i
          when '--sigma'
            $sigma        = arg.to_f
          when '--pidmin'
            $pidmin       = arg.to_f
          when '--pidmax'
            $pidmax       = arg.to_f
          when '--noweight'
            $noweight     = true
          when '--smooth'
            $smooth       = (arg.to_i == 1 ? :full : :partial)
          when '--nosmooth'
            $nosmooth     = true
          when '--scale'
            $scale        = arg.to_f
          when '--add'
            $logger.error "!!! --add option is not supported yet"
            exit 1
            $add          = arg.to_f
          when '--penv'
            $logger.error "!!! --penv option is not supported yet"
            exit 1
            $penv         = true
          when '--heatmap'
            $heatmap      = true
          when '--verbose'
            $logger.level = case arg.to_i
                            when 0 then Logger::ERROR
                            when 1 then Logger::WARN
                            when 2 then Logger::INFO
                            when 3 then Logger::DEBUG
                            else Logger::ERROR
                            end
          when '--version'
            print_version
            exit 0
          end
        end

        # when arguments are nonsense, print usage
        if ((ARGV.length != 0) ||
            (!$tem_list && !$tem_file) ||
            ($tem_list && $tem_file))
          print_usage
          exit 1
        end


        # Part 3.
        #
        # Reading Environment Class Definition File
        #

        # set amino_acids
        $amino_acids = "ACDEFGHIKLMNPQRSTVWY".split("") if $cys == 2

        # an array for storing all environment feature objects
        $env_features = []

        # an array for storing indexes of constrained environment features
        $cst_features = []

        # aa1 amino acid in a substitution itself is a environment feature
        $env_features << EnvironmentFeature.new("sequence",
                                                $amino_acids,
                                                $amino_acids,
                                                "F",
                                                "F")

        # read environment class definiton file and
        # store them into the hash prepared above
        env_index = 1

        IO.foreach($classdef) do |line|
          line.chomp!
          if line.start_with?("#")
            next
          elsif (env_ftr = line.chomp.split(/;/)).length == 5
            $logger.info ">>> An environment feature, #{line} detected"
            if env_ftr[-1] == "T"
              # skip silenced environment feature
              $logger.warn "!!! The environment feature, #{line} silent"
              next
            end
            if env_ftr[-2] == "T"
              $cst_features << env_index
              $logger.warn "!!! The environment feature, #{line} constrained"
            end
            $env_features << EnvironmentFeature.new(env_ftr[0],
                                                    env_ftr[1].split(""),
                                                    env_ftr[2].split(""),
                                                    env_ftr[3],
                                                    env_ftr[4])
            env_index += 1
          else
            $logger.error "@@@ #{line} doesn't seem to be a proper format for class definition"
            exit 1
          end
        end

        # a hash for storing all environment objects
        $envs = {}

        # generate all possible combinations of environment labels, and
        # create & store every environment object into the hash prepared above with the label as a key
        $env_features.inject([]) { |sum, ec|
          sum << ec.labels
        }.inject { |pro, lb|
          pro.product(lb)
        }.each_with_index { |e, i|
          $envs[e.flatten.join] = Environment.new(i, e.flatten.join, $amino_acids)
        }

        # Part 4.
        #
        # Reading TEM file or TEMLIST list file and couting substitutions
        #

        # a global file handle for output
        $outfh = File.open($outfile, "w")

        if $tem_file
          $tem_list_io = StringIO.new($tem_file)
        end

        if $tem_list
          $tem_list_io = File.open($tem_list)
        end

        $tem_list_io.each_line do |tem_file|
          tem_file.chomp!

          $logger.info ">>> Analysing #{tem_file} ..."

          ali = Bio::Alignment::OriginalAlignment.new
          ff  = Bio::FlatFile.auto(tem_file)
          ff.each_entry do |pir|
            if pir.definition == "sequence"
              ali.add_seq(pir.data.gsub("\n", ""), pir.entry_id)
            end
          end

          if ali.size < 2
            $logger.warn "!!! Skipped #{tem_file}, there is only one 'sequence' entry"
            next
          end

          $ali_size   += 1
          env_labels  = {}
          disulphide  = {}

          ali.each_pair do |key, seq|
            # check disulphide bond environment first!
            ff.rewind
            ff.each_entry do |pir|
              if (pir.entry_id == key) && (pir.definition == "disulphide")
                disulphide[key] = pir.data.gsub("\n", "").split("")
              end
            end

            $env_features.each_with_index do |ec, ei|
              env_labels[key] = [] unless env_labels.has_key?(key)

              ff.rewind
              ff.each_entry do |pir|
                if (pir.entry_id == key) && (pir.definition == ec.name)
                  labels = pir.data.gsub("\n", "").split("").map_with_index do |sym, pos|
                    if sym == "-"
                      "-"
                    elsif sym == "X" || sym == "x"
                      "X"
                    else
                      if ei == 0 # Amino Acid Environment Feature
                        (( disulphide.has_key?(key) and disulphide[key][pos] == "F") && (sym == "C")) ? "J" : sym
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
              ali.each_pair do |id2, seq2|
                if id1 != id2
                  pid  = calc_pid(seq1, seq2)
                  s1 = seq1.split("")
                  s2 = seq2.split("")

                  # check PID_MIN
                  if $pidmin && (pid < $pidmin)
                    $logger.info ">>> Skip alignment between #{id1} and #{id2} having PID, #{pid}% less than PID_MIN, #{$pidmin}"
                    next
                  end

                  # check PID_MAX
                  if $pidmax && (pid > $pidmax)
                    $logger.info ">>> Skip alignment between #{id1} and #{id2} having PID, #{pid}% greater than PID_MAX, #{$pidmax}"
                    next
                  end

                  s1.each_with_index do |aa1, pos|
                    aa1.upcase!
                    aa2 = s2[pos].upcase

                    if env_labels[id1][pos].include?("X")
                      $logger.info ">>> Substitutions from #{id1}-#{pos}-#{aa1} were masked"
                      next
                    end

                    if env_labels[id2][pos].include?("X")
                      $logger.info ">>> Substitutions to #{id2}-#{pos}-#{aa2} were masked"
                      next
                    end

                    if !$amino_acids.include?(aa1)
                      $logger.warn "!!! #{id1}-#{pos}-#{aa1} is not a standard amino acid" unless aa1 == "-"
                      next
                    end

                    if !$amino_acids.include?(aa2)
                      $logger.warn "!!! #{id1}-#{pos}-#{aa2} is not a standard amino acid" unless aa2 == "-"
                      next
                    end

                    aa1 = (((disulphide.has_key?(id1) and disulphide[id1][pos] == "F") && (aa1 == "C")) ? "J" : aa1)
                    aa2 = (((disulphide.has_key?(id2) and disulphide[id2][pos] == "F") && (aa2 == "C")) ? "J" : aa2)

                    if $cst_features.empty?
                      $envs[env_labels[id1][pos]].increase_residue_count(aa2)
                    elsif (env_labels[id1][pos].split("").values_at(*$cst_features) == env_labels[id2][pos].split("").values_at(*$cst_features))
                      $envs[env_labels[id1][pos]].increase_residue_count(aa2)
                    else
                      $logger.debug "*** #{id1}-#{pos}-#{aa1} and #{id2}-#{pos}-#{aa2} have different symbols for constrained environment features each other"
                      next
                    end

                    grp_label = env_labels[id1][pos][1..-1]

                    if $env_aa_obs.has_key? grp_label
                      if $env_aa_obs[grp_label].has_key? aa1
                        $env_aa_obs[grp_label][aa1] += 1
                      else
                        $env_aa_obs[grp_label][aa1] = 1
                      end
                    else
                      $env_aa_obs[grp_label] = Hash.new(0)
                      $env_aa_obs[grp_label][aa1] = 1
                    end

                    if $aa_tot_obs.has_key? aa1
                      $aa_tot_obs[aa1] += 1
                    else
                      $aa_tot_obs[aa1] = 1
                    end

                    if aa1 != aa2
                      if $aa_mut_obs.has_key? aa1
                        $aa_mut_obs[aa1] += 1
                      else
                        $aa_mut_obs[aa1] = 1
                      end
                    end
                    $logger.debug "*** Add #{id1}-#{pos}-#{aa1} -> #{id2}-#{pos}-#{aa2} substitution for #{env_labels[id1][pos]}"
                  end
                end
              end
            end
          else
            # BLOSUM-like weighting
            clusters = []
            ali.each_pair { |i, s| clusters << [i] }

            # a loop for single linkage clustering
            begin
              continue = false
              0.upto(clusters.size - 2) do |i|
                indexes = []
                (i + 1).upto(clusters.size - 1) do |j|
                  found = false
                  clusters[i].each do |c1|
                    clusters[j].each do |c2|
                      if calc_pid(ali[c1], ali[c2]) >= $weight
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

            clusters.combination(2).each do |cluster1, cluster2|
              cluster1.each do |id1|
                cluster2.each do |id2|
                  seq1 = ali[id1].split("")
                  seq2 = ali[id2].split("")

                  seq1.each_with_index do |aa1, pos|
                    aa1.upcase!
                    aa2 = seq2[pos].upcase rescue next # should fix this in sane way!

                    if env_labels[id1][pos].include?("X")
                      $logger.debug "*** Substitutions from #{id1}-#{pos}-#{aa1} were masked"
                      next
                    end

                    if env_labels[id2][pos].include?("X")
                      $logger.debug "*** Substitutions to #{id2}-#{pos}-#{aa2} were masked"
                      next
                    end

                    if !$amino_acids.include?(aa1)
                      $logger.warn "!!! #{id1}-#{pos}-#{aa1} is not standard amino acid" unless aa1 == "-"
                      next
                    end

                    if !$amino_acids.include?(aa2)
                      $logger.warn "!!! #{id1}-#{pos}-#{aa2} is not standard amino acid" unless aa2 == "-"
                      next
                    end

                    aa1   = (((disulphide.has_key?(id1) and disulphide[id1][pos] == "F") && (aa1 == "C")) ? "J" : aa1)
                    aa2   = (((disulphide.has_key?(id2) and disulphide[id2][pos] == "F") && (aa2 == "C")) ? "J" : aa2)
                    size1 = cluster1.size
                    size2 = cluster2.size
                    obs1  = 1.0 / size1
                    obs2  = 1.0 / size2

                    if $cst_features.empty?
                      $envs[env_labels[id1][pos]].increase_residue_count(aa2, 1.0 / (size1 * size2))
                      $envs[env_labels[id2][pos]].increase_residue_count(aa1, 1.0 / (size1 * size2))
                    elsif (env_labels[id1][pos].split("").values_at(*$cst_features) == env_labels[id2][pos].split("").values_at(*$cst_features))
                      $envs[env_labels[id1][pos]].increase_residue_count(aa2, 1.0 / (size1 * size2))
                      $envs[env_labels[id2][pos]].increase_residue_count(aa1, 1.0 / (size1 * size2))
                    else
                      $logger.debug "*** #{id1}-#{pos}-#{aa1} and #{id2}-#{pos}-#{aa2} have different symbols for constrained environment features each other"
                      next
                    end

                    grp_label1 = env_labels[id1][pos][1..-1]
                    grp_label2 = env_labels[id2][pos][1..-1]

                    if $env_aa_obs.has_key? grp_label1
                      if $env_aa_obs[grp_label1].has_key? aa1
                        $env_aa_obs[grp_label1][aa1] += obs1
                      else
                        $env_aa_obs[grp_label1][aa1] = obs1
                      end
                    else
                      $env_aa_obs[grp_label1] = Hash.new(0.0)
                      $env_aa_obs[grp_label1][aa1] = obs1
                    end

                    if $env_aa_obs.has_key? grp_label2
                      if $env_aa_obs[grp_label2].has_key? aa2
                        $env_aa_obs[grp_label2][aa2] += obs2
                      else
                        $env_aa_obs[grp_label2][aa2] = obs2
                      end
                    else
                      $env_aa_obs[grp_label2] = Hash.new(0.0)
                      $env_aa_obs[grp_label2][aa2] = obs2
                    end

                    if $aa_tot_obs.has_key? aa1
                      $aa_tot_obs[aa1] += obs1
                    else
                      $aa_tot_obs[aa1] = obs1
                    end

                    if $aa_tot_obs.has_key? aa2
                      $aa_tot_obs[aa2] += obs2
                    else
                      $aa_tot_obs[aa2] = obs2
                    end

                    if aa1 != aa2
                      if $aa_mut_obs.has_key? aa1
                        $aa_mut_obs[aa1] += obs1
                      else
                        $aa_mut_obs[aa1] = obs1
                      end
                      if $aa_mut_obs.has_key? aa2
                        $aa_mut_obs[aa2] += obs2
                      else
                        $aa_mut_obs[aa2] = obs2
                      end
                    end

                    $logger.debug "*** Add #{id1}-#{pos}-#{aa1} -> #{id2}-#{pos}-#{aa2} substitution for #{env_labels[id1][pos]}"
                    $logger.debug "*** Add #{id2}-#{pos}-#{aa2} -> #{id1}-#{pos}-#{aa1} substitution for #{env_labels[id2][pos]}"
                  end
                end
              end
            end
          end # if !$nosmooth
        end

        # print out default header
        $outfh.puts <<HEADER
#
# Environment-specific amino acid substitution matrices
# Creator: egor version #{Egor::VERSION}
# Creation Date: #{Time.now.strftime("%d/%m/%Y %H:%M")}
#
# Definitions for structural environments:
# #{$env_features.size - 1} features used
#
HEADER

        $env_features[1..-1].each { |e| $outfh.puts "# #{e}" }

        $outfh.puts <<HEADER
#
# (read in from #{$classdef})
#
# Number of alignments: #{$ali_size}
# (list of .tem files read in from #{$tem_list})
#
# Total number of environments: #{Integer($envs.size / $amino_acids.size)}
#
# There are #{$amino_acids.size} amino acids considered.
# #{$amino_acids.join}
# 
HEADER

        if $noweight
          $outfh.puts "# Weighting scheme: none"
        else
          $outfh.puts "# Weighting scheme: clustering at PID #{$weight} level"
        end

        # calculate amino acid frequencies and mutabilities, and
        # print them as default statistics in the header part
        ala_factor  = if $aa_tot_obs["A"] == 0
                        0.0
                      elsif $aa_mut_obs["A"] == 0
                        0.0
                      else
                        100.0 * $aa_tot_obs["A"] / $aa_mut_obs["A"].to_f
                      end
        $tot_aa     = $aa_tot_obs.values.sum

        $outfh.puts "#"
        $outfh.puts "# Total amino acid frequencies:\n"
        $outfh.puts "# %-3s %9s %9s %5s %8s %8s" % %w[RES TOT_OBS MUT_OBS MUTB REL_MUTB REL_FRQ]

        $amino_acids.each do |res|
          $aa_mutb[res]     = $aa_tot_obs[res] == 0 ? 1.0 : $aa_mut_obs[res] / $aa_tot_obs[res].to_f
          $aa_rel_mutb[res] = $aa_mutb[res] * ala_factor
          $aa_rel_freq[res] = $aa_tot_obs[res] == 0 ? 0.0 : $aa_tot_obs[res] / $tot_aa.to_f
        end

        $amino_acids.each do |res|
          if $noweight
            $outfh.puts "# %-3s %9d %9d %5.2f %8d %8.4f" %
              [res, $aa_tot_obs[res], $aa_mut_obs[res], $aa_mutb[res], $aa_rel_mutb[res], $aa_rel_freq[res]]
          else
            $outfh.puts "# %-3s %9.2f %9.2f %5.2f %8d %8.4f" %
              [res, $aa_tot_obs[res], $aa_mut_obs[res], $aa_mutb[res], $aa_rel_mutb[res], $aa_rel_freq[res]]
          end
        end


        # Part 5.
        #
        # Calculating substitution frequency tables
        #

        # calculating probabilities for each environment
        $envs.values.each do |e|
          if e.freq_array.sum != 0
            e.prob_array = 100.0 * e.freq_array / e.freq_array.sum
          end
        end

        # count raw frequencies
        $tot_freq_mat = ($noweight ? NMatrix.int($amino_acids.size,$amino_acids.size) : NMatrix.float($amino_acids.size,$amino_acids.size))

        # for each combination of environment features
        env_groups = $envs.values.group_by { |env| env.label[1..-1] }

        env_groups.to_a.sort_by { |env_group|
          # a bit clumsy sorting here...
          env_group[0].split("").map_with_index { |l, i|
            $env_features[i + 1].labels.index(l)
          }
        }.each_with_index do |group, group_no|
          grp_freq_mat = ($noweight ? NMatrix.int($amino_acids.size,$amino_acids.size) : NMatrix.float($amino_acids.size,$amino_acids.size))

          $amino_acids.each_with_index do |aa, ai|
            freq_array = group[1].find { |e| e.label.start_with?(aa) }.freq_array
            0.upto($amino_acids.size - 1) { |j| grp_freq_mat[ai, j] = freq_array[j] }
          end

          $tot_freq_mat += grp_freq_mat

          if $output == 0
            $outfh.puts ">#{group[0]} #{group_no}"
            $outfh.puts grp_freq_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
          end
        end

        if $output == 0
          $outfh.puts ">Total"
          $outfh.puts $tot_freq_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
          exit 0
        end


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

        if ($output > 0) && $nosmooth
          # Probability matrices
          $tot_prob_mat = NMatrix.float($amino_acids.size, $amino_acids.size)

          # for each combination of environment features
          env_groups = $envs.values.group_by { |env| env.label[1..-1] }
          env_groups.to_a.sort_by { |env_group|
            # a bit clumsy sorting here...
            env_group[0].split("").map_with_index { |l, i|
              $env_features[i + 1].labels.index(l)
            }
          }.each_with_index do |group, group_no|
            grp_prob_mat = NMatrix.float($amino_acids.size,$amino_acids.size)

            $amino_acids.each_with_index do |aa, ai|
              prob_array = group[1].find { |e| e.label.start_with?(aa) }.prob_array
              0.upto($amino_acids.size - 1) { |j| grp_prob_mat[ai, j] = prob_array[j] }
            end

            $tot_prob_mat += grp_prob_mat

            if ($output == 1)
              $outfh.puts ">#{group[0]} #{group_no}"
              $outfh.puts grp_prob_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
            end
          end

          if ($output == 1)
            $outfh.puts ">Total"
            $outfh.puts $tot_prob_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
            $outfh.close
            exit 0
          end
        end

        # for smoothing...
        if ($output > 0) && !$nosmooth
          #
          # p1 probability
          #
          p1      = NArray.float($amino_acids.size)
          a0      = NArray.float($amino_acids.size).fill(1.0 / $amino_acids.size)
          big_N   = $tot_aa.to_f
          small_n = $amino_acids.size.to_f
          omega1  = 1.0 / (1 + big_N / ($sigma * small_n))
          omega2  = 1.0 - omega1

          if $smooth == :partial
            # for partial smoothing, p1 probability is not smoothed!
            0.upto($amino_acids.size - 1) { |i| p1[i] = 100.0 * $aa_rel_freq[$amino_acids[i]] }
            $smooth_prob[1] = p1
            puts p1.to_a.join("\n")
          else
            # for full smoothing, p1 probability is smoothed
            0.upto($amino_acids.size - 1) { |i| p1[i] = 100.0 * (omega1 * a0[i] + omega2 * $aa_rel_freq[$amino_acids[i]]) }
            $smooth_prob[1] = p1
          end

          #
          # p2 and above
          #
          env_labels = $env_features.map_with_index {|ef, ei| ef.labels.map { |l| "#{ei}#{l}" } }

          if $smooth == :partial
            $outfh.puts <<HEADER
#
# Partial Smoothing:
#
# p1(ri) (i.e., amino acid composition) is estimated by summing over
# each row in all matrices (no smoothing)
#                           ^^^^^^^^^^^^
# p2(ri|Rj) is estimated as:
#    p2(ri|Rj) = omega1 * p1(ri) + omega2 * W2(ri|Rj)
# 
# p3(ri|Rj,fq) is estimated as:
#    p3(ri|Rj,fq) = omega1 * A2(ri|fq) + omega2 * W3(ri|Rj,fq)
# where
#    A2(ri|fq) = p2(ri|fq) (fixed fq; partial smoothing)
# 
# The smoothing procedure is curtailed here and finally
# p5(ri|Rj,...) is estimated as:
#    p5(ri|Rj,...) = omega1 * A3(ri|Rj,fq) + omega2 * W5(ri|Rj...)
# where
#    A3(ri|Rj,fq) = sum over fq omega_c * pc3(Rj,fq)
# 
# Weights (omegas) are calculated as in Topham et al. 1993)
# 
# sigma value used is:  5.00
#
HEADER
            1.upto($env_features.size) do |ci|
              # for partial smoothing, only P1 ~ P3, and Pn are considered
              next if (ci > 2) && (ci < $env_features.size)

              env_labels.combination(ci) do |c1|
                Enumerable.cart_prod(*c1).each do |labels|
                  pattern = "." * $env_features.size

                  labels.each do |label|
                    i = label[0].chr.to_i
                    l = label[1].chr
                    pattern[i] = l
                  end

                  if pattern =~ /^\./
                    $logger.debug "*** Skipped environment, #{pattern}, for partial smoothing"
                    next
                  end

                  # get environmetns, frequencies, and probabilities
                  envs      = $envs.values.select { |env| env.label.match(pattern.to_re) }
                  freq_arr  = envs.inject(NArray.float($amino_acids.size)) { |sum, env| sum + env.freq_array }
                  prob_arr  = NArray.float($amino_acids.size)
                  0.upto($amino_acids.size - 1) { |i| prob_arr[i] = (freq_arr[i] == 0 ? 0 : freq_arr[i] / freq_arr.sum.to_f) }

#                  # assess whether a residue type j is compatible with a particular combination of structural features
#                  # corrections for non-zero colum vector phenomenon by switching the smoothing procedure off as below
#                  if ci == $env_features.size
#                    aa_label        = labels.find { |l| l.match(/^0/) }[1].chr
#                    sub_pattern     = "." * $env_features.size
#                    sub_pattern[0]  = aa_label
#                    sub_freq_sum    = 0
#
#                    labels[1..-1].each do |label|
#                      next if label.start_with?("0")
#                      i               = label[0].chr.to_i
#                      l               = label[1].chr
#                      sub_pattern[i]  = l
#                      sub_envs        = $envs.values.select { |env| env.label.match(pattern.to_re) }
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
#                      $logger.warn "!!! Smoothing procedure is off for the environment feature combination, #{pattern}"
#                      next
#                    end
#                  end

                  # collect priors if ci > 1
                  priors  = []

                  if ci == 2
                    labels.combination(1).select { |c2| c2[0].start_with?("0") }.each { |c3|
                      priors << $smooth_prob[2][c3.to_set]
                    }
                  elsif ci == $env_features.size
                    labels.combination(2).select { |c2| c2[0].start_with?("0") || c2[1].start_with?("0") }.each { |c3|
                      priors << $smooth_prob[3][c3.to_set]
                    }
                  end

                  # entropy based weighting priors
                  entropy_max     = Math::log($amino_acids.size)
                  entropies       = priors.map { |prior| -1.0 * prior.to_a.inject(0.0) { |s, p|
                    begin
                      p == 0.0 ? s - 1 : s + p * Math::log(p)
                    rescue
                      #puts "P: #{p}"
                    end
                  } }
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
                  smooth_prob_arr_sum = smooth_prob_arr.sum
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (smooth_prob_arr[i] / smooth_prob_arr_sum) }

                  # store smoothed probabilties in a hash using a set of envrionment labels as a key
                  if !$smooth_prob.has_key?(ci + 1)
                    $smooth_prob[ci + 1] = {}
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  else
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  end
                end
              end
            end
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
#
# pn(ri|f1q,f2q,...,fn-1q) is estimated as:
#    pn(ri|f1q,f2q,...,fn-1q) = omega1 * An-1(ri|f1q, f2q,...,fn-2q) + omega2 * W5(ri|f1q,f2q,...,fn-1q)
# where
#    An-1(ri|f1q,f2q,...,fn-2q) = sum over fq omega_c * pcn-1(f1q,f2q,...,fn-2q)
# 
# Weights (omegas) are calculated as in Topham et al. 1993)
# 
# sigma value used is:  5.00
#
HEADER
            # full smooting
            1.upto($env_features.size) do |ci|
              env_labels.combination(ci) do |c1|
                Enumerable.cart_prod(*c1).each do |labels|
                  pattern = "." * $env_features.size
                  labels.each do |label|
                    j = label[0].chr.to_i
                    l = label[1].chr
                    pattern[j] = l
                  end

                  # get environmetns, frequencies, and probabilities
                  envs      = $envs.values.select { |env| env.label.match(pattern.to_re) }
                  freq_arr  = envs.inject(NArray.float($amino_acids.size)) { |sum, env| sum + env.freq_array }
                  prob_arr  = NArray.float($amino_acids.size)
                  0.upto($amino_acids.size - 1) { |i| prob_arr[i] = freq_arr[i] == 0 ? 0 : freq_arr[i] / freq_arr.sum.to_f }

                  # collect priors
                  priors  = []
                  if ci > 1
                    labels.combination(ci - 1).each { |c2| priors << $smooth_prob[ci][c2.to_set] }
                  else
                    priors << $smooth_prob[1]
                  end

                  # entropy based weighting priors
                  entropy_max = Math::log($amino_acids.size)
                  entropies = priors.map do |prior|
                    (entropy_max + prior.to_a.inject(0.0) { |s, p| s + p * Math::log(p) }) / entropy_max
                  end
                  weighted_priors = priors.map_with_index { |p, i| p * entropies[i] / entropies.sum }.sum

                  # smoothing step
                  smooth_prob_arr = NArray.float($amino_acids.size)
                  big_N           = freq_arr.sum.to_f
                  small_n         = $amino_acids.size.to_f
                  omega1          = 1.0 / (1 + big_N / ($sigma * small_n))
                  omega2          = 1.0 - omega1
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (omega1 * weighted_priors[i] + omega2 * prob_arr[i]) }

                  # normalization step
                  smooth_prob_arr_sum = smooth_prob_arr.sum
                  0.upto($amino_acids.size - 1) { |i| smooth_prob_arr[i] = 100.0 * (smooth_prob_arr[i] / smooth_prob_arr_sum) }

                  # store smoothed probabilties in a hash using a set of envrionment labels as a key
                  if !$smooth_prob.has_key?(ci + 1)
                    $smooth_prob[ci + 1] = {}
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  else
                    $smooth_prob[ci + 1][labels.to_set] = smooth_prob_arr
                  end
                end
              end
            end
          end

          # updating smoothed probability array for each envrionment
          $envs.values.each { |e| e.smooth_prob_array = $smooth_prob[$env_features.size + 1][e.label_set] }

          # for a total substitution probability matrix
          $tot_prob_mat = NMatrix.float($amino_acids.size,$amino_acids.size)

          # grouping environments by its environment labels but amino acid label
          env_groups = $envs.values.group_by { |env| env.label[1..-1] }

          # sorting environments and build 21X21 substitution matrices
          env_groups.to_a.sort_by { |env_group|
            # a bit clumsy sorting here...
            env_group[0].split("").map_with_index { |l, i|
              $env_features[i + 1].labels.index(l)
            }
          }.each_with_index do |group, group_no|
            # calculating 21X21 substitution probability matrix for each envrionment
            grp_prob_mat = NMatrix.float($amino_acids.size,$amino_acids.size)

            $amino_acids.each_with_index do |aa, ai|
              smooth_prob_array = group[1].find { |e| e.label.start_with?(aa) }.smooth_prob_array
              0.upto($amino_acids.size - 1) { |j| grp_prob_mat[ai, j] = smooth_prob_array[j] }
            end

            $tot_prob_mat += grp_prob_mat

            if $output == 1
              $outfh.puts ">#{group[0]} #{group_no}"
              $outfh.puts grp_prob_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
            end
          end

          $tot_prob_mat /= env_groups.size

          if $output == 1
            $outfh.puts ">Total"
            $outfh.puts $tot_prob_mat.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
            $outfh.close
            exit 0
          end


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
# which were derived from the environment-independent amino acid frequencies.
#                             ^^^^^^^^^^^^^^^^^^^^^^^
HEADER
            else
              $outfh.puts <<HEADER
# which were derived from the environment-dependent amino acid frequencies.
#                             ^^^^^^^^^^^^^^^^^^^^^
HEADER
            end

            $tot_logo_mat = $cys == 0 ? NMatrix.float($amino_acids.size, $amino_acids.size + 1) : NMatrix.float($amino_acids.size, $amino_acids.size)
            grp_logo_mats = []
            factor        = $scale / Math::log(2)

            # grouping environments by its environment labels but amino acid label
            env_groups = $envs.values.group_by { |env| env.label[1..-1] }

            # sorting environments and build 21X21 substitution matrices
            env_groups.to_a.sort_by { |env_group|
              # a bit clumsy sorting here...
              env_group[0].split("").map_with_index { |l, i|
                $env_features[i + 1].labels.index(l)
              }
            }.each_with_index do |group, group_no|
              # calculating 21X21 substitution probability matrix for each envrionment
              grp_label     = group[0]
              grp_envs      = group[1]
              grp_logo_mat  = $cys == 0 ? NMatrix.float($amino_acids.size, $amino_acids.size + 1) : NMatrix.float($amino_acids.size, $amino_acids.size)

              $amino_acids.each_with_index do |aa, ai|
                env       = grp_envs.detect { |e| e.label.start_with?(aa) }
                logo_arr  = $cys == 0 ? NArray.float($amino_acids.size + 1) : NArray.float($amino_acids.size)

                env.smooth_prob_array.to_a.each_with_index do |prob, j|
                  paj         = 100.0 * $aa_rel_freq[$amino_acids[j]]
                  odds        = prob == 0.0 ? 0.000001 / paj : prob / paj
                  logo_arr[j] = factor * Math::log(odds)
                end

                0.upto($amino_acids.size - 1) { |j| grp_logo_mat[ai, j] = logo_arr[j] }

                # adding log odds ratio for "U" (J or C) when --cyc is 0
                if $cys == 0
                  paj   = 100.0 * ($aa_rel_freq["C"] + $aa_rel_freq["J"])
                  prob  = env.smooth_prob_array[$amino_acids.index("C")] + env.smooth_prob_array[$amino_acids.index("J")]
                  odds  = prob == 0.0 ? 0.000001 / paj : prob / paj
                  logo_arr[logo_arr.size - 1] = factor * Math::log(odds)
                  grp_logo_mat[ai, logo_arr.size - 1] = logo_arr[logo_arr.size - 1]
                end
              end

              $tot_logo_mat += grp_logo_mat
              grp_logo_mats << [grp_label, grp_logo_mat]
            end

            $tot_logo_mat /= env_groups.size

            # calculating relative entropy for each amino acid pair H and
            # the expected score E in bit units
            #
            # I'm a bit suspicious about this part...
            tot_E = 0.0
            tot_H = 0.0

            0.upto($tot_logo_mat.shape[0] - 1) do |i|
              0.upto($tot_logo_mat.shape[0] - 1) do |j|
                if i != j
                  tot_E += $tot_logo_mat[i, j] * $aa_rel_freq[$amino_acids[i]] * $aa_rel_freq[$amino_acids[j]] / 2.0
                  tot_H += $tot_logo_mat[i, j] * $tot_prob_mat[i, j] / 2.0 / 10000.0
                else
                  tot_E += $tot_logo_mat[i, j] * $aa_rel_freq[$amino_acids[i]] * $aa_rel_freq[$amino_acids[j]]
                  tot_H += $tot_logo_mat[i, j] * $tot_prob_mat[i, j] / 10000.0
                end
              end
            end

            $outfh.puts <<HEADER
# 
# Shown here are logarithms of these values multiplied by #{$scale}/log(2) 
# rounded to the nearest integer (log-odds scores in 1/3 bit units).
# 
# For total (composite) matrix, Entropy = #{"%5.4f" % tot_H} bits, Expected score = #{"%5.4f" % tot_E}
#
HEADER

            grp_logo_mats.each_with_index do |arr, grp_no|
              grp_label     = arr[0]
              grp_logo_mat  = arr[1]

              $outfh.puts ">#{grp_label} #{grp_no}"
              if $cys
                $outfh.puts grp_logo_mat.round.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids + %w[U])
              else
                $outfh.puts grp_logo_mat.round.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
              end
            end

            $outfh.puts ">Total #{grp_logo_mats.size}"

            if $cys == 0
              $outfh.puts $tot_logo_mat.round.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids + %w[U])
            else
              $outfh.puts $tot_logo_mat.round.pretty_string(:col_header => $amino_acids, :row_header => $amino_acids)
            end
            $outfh.close
            exit 0
          end
        end
      end

    end # class << self
  end # class CLI
end # module Egor
