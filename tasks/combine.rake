require 'fork_manager'

namespace :combine do

  cur_dir   = Pathname.new(__FILE__).dirname.realpath
  data_dir  = cur_dir + "../data"
  tmp_dir   = cur_dir + "../tmp"

  desc "Generate ESSTS from DNA/RNA-binding representative alignmenst using multiple PID cutoffs"
  task :aligns do

    nas = %w[dna rna]
    nas.each do |na|
      pids.each do |pid|
        fm = ForkManager.new(2)
        fm.manage do
          outs.each do |out|
            fm.fork do
              classdef  = "./classdef_#{na}128.dat"
              listfile  = "./bipa_scop_repfam_#{na}_joytem.lst"
              outfile   = "../tmp/mat/ulla-essts128-#{na}-pid#{pid}-out#{out}.mat"
              command   = "../bin/ulla -c #{classdef} -l #{listfile} -w #{pid} --sigma 0.002 --output #{out} -o #{outfile}"
              cd data_dir
              system command
              cd cur_dir
            end
          end
        end
      end
    end
  end

end
