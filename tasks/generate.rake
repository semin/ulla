namespace :generate do

  desc "Generate ESSTS from subsets of DNA/RNA-binding protein alignments for jackknife test"
  task :jack do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    bin_dir   = cur_dir   + "../bin"
    data_dir  = cur_dir   + "../data"
    mat_dir   = data_dir  + "mats"
    list_dir  = mat_dir   + "lists"
    jack_dir  = mat_dir   + "jack"
    nas       = %w[dna rna]
    outs      = (1..2)

    nas.each do |na|
      tems  = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
      fm    = ForkManager.new(8)
      fm.manage do
        (0...tems.size).each do |i|
          fm.fork do
            jtems = tems - [tems[i]]
            list  = jack_dir + "bipa-scop-repfam-#{na}-joytem-jack#{i}.lst"
            list.open('w') { |f| f.puts jtems }
            outs.each do |out|
              classdef  = data_dir + "classdef-#{na}128.dat"
              outfile   = jack_dir + "ulla-#{na}128-jack#{i}-out#{out}.mat"
              command   = "#{bin_dir}/ulla -y 2 -c #{classdef} -l #{list} --sigma 1 --output #{out} -o #{outfile}"
              system command
            end
          end
        end
      end
    end
  end


  desc "Generate ESSTs from DNA/RNA-binding family alignments using multiple PID cutoffs and sigma values"
  task :essts do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    bin_dir   = cur_dir   + "../bin"
    data_dir  = cur_dir   + "../data"
    mat_dir   = data_dir  + "mats"
    list_dir  = mat_dir   + "lists"
    nas       = %w[dna rna]
    envs      = [64, 128]
    pids      = (40..90).step(10)
    #sigmas    = [0.0001, 0.001, 0.01, 0.1, 1, 3, 5]
    sigmas    = [0.1]
    outs      = (0..2)

    fm = ForkManager.new(6)
    fm.manage do
      nas.each do |na|
        tems = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
        list = list_dir + "generate-essts-bipa-scop-repfam-#{na}-joytem.lst"
        list.open('w') { |f| f.puts tems }

        envs.each do |env|
          pids.each do |pid|
            fm.fork do
              sigmas.each do |sigma|
                outs.each do |out|
                  classdef  = data_dir  + "classdef-#{na}#{env}.dat"
                  outfile   = mat_dir   + "ulla-#{na}#{env}-pid#{pid}-sigma#{sigma}-out#{out}.mat"
                  command   = "#{bin_dir}/ulla -y 2 -c #{classdef} -l #{list} --weight #{pid} --sigma #{sigma} --output #{out} -o #{outfile}"
                  system command
                end
              end
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
      fm = ForkManager.new(6)
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
      fm = ForkManager.new(6)
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


  desc "Generate frequency tables from DNA/RNA-binding representative alignments using multiple PID cutoffs and reduced number of environment features: only DNA/RNA binding status"
  task :reduced_essts do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    bin_dir   = cur_dir   + "../bin"
    data_dir  = cur_dir   + "../data"
    mat_dir   = data_dir  + "mats"
    list_dir  = mat_dir   + "lists"
    nas       = %w[dna rna]
    pids      = (30..100).step(10)

    nas.each do |na|
      tems  = Pathname.glob(data_dir + "bipa/scop/rep/#{na}/*/#{na}*.tem").map(&:realpath)
      fm    = ForkManager.new(8)
      fm.manage do
        pids.each do |pid|
          fm.fork do
            list = list_dir + "bipa-scop-repfam-#{na}-joytem.lst"
            list.open('w') { |f| f.puts tems }
            classdef  = data_dir  + "classdef-#{na}2.dat"
            outfile   = mat_dir   + "ulla-#{na}2-pid#{pid}-out0.mat"
            command   = "#{bin_dir}/ulla -y 2 -c #{classdef} -l #{list} -w #{pid} --output 0 -o #{outfile}"
            system command
          end
        end
      end
    end
  end


  desc "Generate CSV file for MDS analysis of ESSTs"
  task :csv do
    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    data_dir  = cur_dir   + "../data"
    mat_dir   = data_dir  + "mats"
    mds_dir   = data_dir  + "mds"
    nas       = %w[dna rna]

    nas.each do |na|
      file = mds_dir + "ulla-#{na}128-pid60-sigma0.002-out2-mds.csv"
      file.open('w') do |file|
        mat = mat_dir + "ulla-#{na}128-pid60-sigma0.002-out2.mat"
        essts = Ulla::Essts.new(mat)
        essts.essts.each do |esst|
          cols = [esst.label]
          (0...20).each do |j|
            cols.concat(esst.matrix[0..-1, j].to_a.flatten)
          end
          file.puts cols.join(", ")
        end
      end
    end
  end

end
