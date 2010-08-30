require 'fork_manager'

namespace :generate do

  cur_dir   = Pathname.new(__FILE__).dirname.realpath
  data_dir  = cur_dir + "../data"
  tmp_dir   = cur_dir + "../tmp"

  desc "Generate ESSTS from DNA/RNA-binding representative alignments using multiple PID cutoffs"
  task :essts do

    nas   = %w[dna rna]
    pids  = (30..100).step(10)
    outs  = (0..2)

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


  desc "Generate combined DNA/RNA-binding representative alignments"
  task :msa do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    tmp_dir   = cur_dir + "../tmp"
    blast_dir = tmp_dir + "./blast"
    msa_dir   = tmp_dir + "./msa"

    %w[dna rna].each do |na|
      fm = ForkManager.new(2)
      fm.manage do
        tems = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
        tems.each do |tem|
          fm.fork do
            sunid = tem.to_s.match(/(\d+)/)[1]
            msa   = msa_dir + "#{na}/#{sunid}.tem"
            msa.open('w') do |file|
              ff1 = Bio::FlatFile.auto(tem)
              ff1.each_entry do |ent|
                if (ent.definition == 'sequence')
                  afa = msa_dir + "#{na}/#{ent.entry_id}.afa"
                  ff2 = Bio::FlatFile.auto(afa)
                  al  = Bio::Alignment.new
                  ff2.entries.each { |e| al.add_seq(e.to_biosequence) }
                  i = 1
                  nogaps = []
                  al.each_site do |s|
                    nogaps << i if s[0] != '-'
                    i += 1
                  end
                  j = 0
                  al.each_seq do |seq|
                    file.puts ">P1;#{al.sequence_names[j]}-#{ent.entry_id}"
                    file.puts (j == 0 ? 'structure' : 'sequence')
                    ns = seq.splice("join(#{nogaps.join(',')})")
                    si = 0
                    ni = 0
                    ent.aaseq.each_char do |c|
                      if c == '-'
                        file.print '-'
                      else
                        file.print ns[si]
                        si +=1
                      end
                      ni += 1
                      file.puts if ni % 75 == 0
                    end
                    j +=1
                    file.puts "*"
                  end
                else
                  file.puts ent
                end
              end
            end
          end
        end
      end
    end
  end


  desc "Generate ESSTS from enriched DNA/RNA-binding representative alignments using multiple PID cutoffs"
  task :essts2 do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    tmp_dir   = cur_dir + "../tmp"
    msa_dir   = tmp_dir + "./msa"
    nas       = %w[dna rna]
    pids      = (30..100).step(10)
    outs      = (0..2)

    nas.each do |na|
      tems  = Pathname.glob(msa_dir + "#{na}/*.tem")
      list  = tmp_dir + "bipa_scop_repfam_enriched_joytem-#{na}.lst"
      list.open('w') { |f| f.puts tems }
      fm = ForkManager.new(2)
      fm.manage do
        pids.each do |pid|
          fm.fork do
            outs.each do |out|
              classdef  = "../data/classdef_#{na}128.dat"
              outfile   = "./mat/ulla-enriched-essts128-#{na}-pid#{pid}-out#{out}.mat"
              command   = "../bin/ulla -c #{classdef} -l #{list} -w #{pid} --autosigma --output #{out} -o #{outfile}"
              cd tmp_dir
              system command
              cd cur_dir
            end
          end
        end
      end
    end
  end

end
