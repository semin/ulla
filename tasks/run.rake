require 'bio'
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
      fm = ForkManager.new(2)
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

end
