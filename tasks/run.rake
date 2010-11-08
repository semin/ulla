require 'fork_manager'

namespace :run do

  task :count do
    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    data_dir  = cur_dir + "../data"
    %w[dna rna].each do |na|
      tems = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
      puts "#{na}: #{tems.size}"
    end
  end


  desc "Run BLAST for each entry in the DNA/RNA-binding representative alignments to find close homologs"
  task :blast do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    data_dir  = cur_dir + "../data"
    tmp_dir   = cur_dir + "../tmp"
    blast_dir = tmp_dir + "./blast"
    nr100     = data_dir + "./uniref100_20100826.fasta"

    %w[dna rna].each do |na|
      tems = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
      tems.each do |tem|
        ff = Bio::FlatFile.auto(tem)
        ff.each_entry do |ent|
          if (ent.definition == 'sequence')
            inp = blast_dir + "#{na}/#{ent.entry_id}.fa"
            out = blast_dir + "#{na}/#{ent.entry_id}.xml"
            inp.open('w') do |f|
              f.puts ">#{ent.entry_id}"
              f.puts ent.aaseq.gsub('-','')
            end
            cmd = "blastall -p blastp -i #{inp} -d #{nr100} -e 0.000001 -a 2 -m 7 -o #{out}"
            system cmd
          end
        end
      end
    end
  end


  desc "Run MAFFT for each entry from representative alignments and its blast hits"
  task :muscle do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    data_dir  = cur_dir + "../data"
    tmp_dir   = cur_dir + "../tmp"
    blast_dir = tmp_dir + "./blast"
    msa_dir   = tmp_dir + "./msa"

    %w[dna rna].each do |na|
      fm = ForkManager.new(6)
      fm.manage do
        tems = Pathname.glob(data_dir + "./bipa/scop/rep/#{na}/*/#{na}*.tem")
        tems.each do |tem|
          fm.fork do
            ff = Bio::FlatFile.auto(tem)
            ff.each_entry do |ent|
              if (ent.definition == 'sequence')
                inp = blast_dir + "#{na}/#{ent.entry_id}.fa"
                out = blast_dir + "#{na}/#{ent.entry_id}.xml"
                afa = msa_dir + "#{na}/#{ent.entry_id}.afa"
                mfa = msa_dir + "#{na}/#{ent.entry_id}.mfa"
                mfa.open('w') do |file|
                  file.puts ">#{ent.entry_id}"
                  file.puts ent.aaseq.gsub('-','')

                  report = Bio::Blast::Report.new(IO.read(out))
                  report.each do |hit|
                    if hit.evalue < 10e-6 && hit.identity > 60 && hit.identity < 80
                      file.puts ">#{hit.target_id}"
                      file.puts hit.target_seq.gsub('-','')
                    end
                  end
                end
                system "muscle -quiet -stable -in #{mfa} -out #{afa}"
              end
            end
          end
        end
      end
    end
  end


  desc "Jackknife test using a collection of subsets for ESSTs"
  task :jackknife do

    cur_dir   = Pathname.new(__FILE__).dirname.realpath
    data_dir  = cur_dir   + "../data"
    mat_dir   = data_dir  + "mats"
    jack_dir  = mat_dir   + "jack"
    nas       = %w[dna rna]
    nas.each do |na|
      ori_essts = Ulla::Essts.new(mat_dir + "ulla-#{na}128-pid60-sigma0.002-out2.mat")

      essts_hsh = {}
      jack_essts = Pathname.glob(jack_dir + "ulla-#{na}128-jack*-out2.mat")
      jack_essts.each do |file|
        essts = Ulla::Essts.new(file)
        essts.essts.each do |esst|
          if essts_hsh.has_key?(esst.label)
            essts_hsh[esst.label] << esst
          else
            essts_hsh[esst.label] = []
            essts_hsh[esst.label] << esst
          end
        end
      end

      essts_hsh.each do |label, essts|
        puts "Label: #{label}"

        tot = NMatrix.float(20, 20).fill!(0)

        essts.each do |esst|
          tot += esst.matrix
        end

        mean = tot / essts.size

        bias = NMatrix.float(20,20).fill!(0)

        (0...20).each do |i|
          (0...20).each do |j|
            bias[i, j] = (essts.size - 1) * (mean[i, j] - ori_essts[label].matrix[i, j])
          end
        end

        puts "Jackknife estimation of bias:"
        puts "MIN: #{bias.min}"
        puts "MAX: #{bias.max}"

        (0...20).each do |j|
          fmt = (["%6.4f"] * 20).join(' ')
          puts fmt % bias[0..-1, j].to_a.flatten
        end

        #jack = NMatrix.float(20,20).fill!(0.0)

        #essts.each do |esst|
          #diff = NMatrix.float(20, 20)
          #(0...20).each do |i|
            #(0...20).each do |j|
              #diff[i, j] = (esst.matrix[i, j] - mean[i, j])**2
              ##puts "ESST[#{i}, #{j}]: #{esst.matrix[i, j]}, MEAN[#{i}, #{j}]: #{mean[i, j]}"
              ##puts "(ESST[#{i}, #{j}] - MEAN[#{i}, #{j}])**2: #{diff[i, j]}"
              #jack[i, j] += diff[i, j]
            #end
          #end
        #end

        #final = NMatrix.float(20,20).fill!(0.0)
        #final = NMath.sqrt(jack * ((essts.size - 1) / Float(essts.size)))

        #puts "Jackknife estimation of standard error: "

        #(0...20).each do |j|
          #fmt = (["%6.4f"] * 20).join(' ')
          #puts fmt % final[0..-1, j].to_a.flatten
        #end
      end
    end
  end

end
