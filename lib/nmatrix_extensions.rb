require 'rubygems'
require 'narray'
require 'facets'

begin
  require 'rvg/rvg'
  include Magick
rescue
  $logger.warn "A RubyGems package, 'rmagick' is not found, so heat maps cannot be generated."
  $no_rmagick = true
end

module NMatrixExtensions

  def pretty_string(options={})
    opts = {:col_header   => nil,
            :row_header   => nil }.merge(options)

    ("%-3s" % "#") + opts[:col_header].inject("") { |s, a|
      s + ("%7s" % a)
    } + "\n" + self.to_a.map_with_index { |a, i|
      ("%-3s" % opts[:row_header][i]) + a.inject("") { |s, v|
        if v.is_a? Float
          s + ("%7.2f" % v)
        else
          s + ("%7d" % v)
        end
      }
    }.join("\n")
  end

  def print_heatmap(options={})
    if $no_rmagick
      return nil
    end

    opts = {:col_header           => 'ACDEFGHIKLMNPQRSTVWYJ'.split(''),
            :row_header           => 'ACDEFGHIKLMNPQRSTVWYJ'.split(''),
            :max_val              => self.max,
            :mid_val              => (self.max - self.min) / 2.0,
            :min_val              => self.min,
            :dpi                  => 100,
            :margin               => 70,
            :rvg_width            => 1200,
            :rvg_height           => 1400,
            :canvas_width         => 900,
            :canvas_height        => 1200,
            :cell_width           => 40,
            :cell_height          => 40,
            :cell_border          => 1,
            :header_height        => 100,
            :footer_height        => 100,
            :gradient_width       => 600,
            :gradient_height      => 60,
            :gradient_start_color => '#FFF',
            :gradient_mid_color   => nil,
            :gradient_end_color   => '#F00',
            :font_scale           => 0.9,
            :font_family          => 'san serif',
            :delta                => 4,
            :title?               => true,
            :title                => '',
            :title_font_size      => 50,
            :print_values?        => true,
            :key_font_size        => 30,
            :value_font_size      => 20,
            :background           => 'white',
            :ext                  => 'gif' }.merge(options)

    RVG::dpi = opts[:dpi]

    rvg = RVG.new(opts[:rvg_width], opts[:rvg_height]) do |canvas|
      title_x = (opts[:canvas_width] - opts[:title].length * opts[:title_font_size] * 0.6) / 2
      title_y = opts[:title_font_size]

      canvas.viewbox(0, 0, opts[:canvas_width], opts[:canvas_height])
      canvas.background_fill = opts[:background]
      canvas.desc = opts[:title]

      if opts[:title?]
        canvas.text(title_x, title_y, opts[:title]).styles(:font_size => opts[:title_font_size])
      end

      # border for whole matrix
      canvas.rect(self.shape[0] * opts[:cell_width],
                  self.shape[1] * opts[:cell_height],
                  opts[:cell_width],
                  opts[:cell_height] + opts[:header_height]).styles(:stroke => 'black',
                                                                    :stroke_width => 4)

      # drawing column and row labels
      0.upto(self.shape[0] - 1) do |col|
        canvas.text((col + 1) * opts[:cell_width] + opts[:delta],
                    opts[:cell_height] + opts[:header_height] - opts[:delta],
                    opts[:col_header][col]).styles( :font_family  => opts[:font_family],
                                                    :font_size    => opts[:cell_width] * opts[:font_scale])
      end

      0.upto(self.shape[1] - 1) do |row|
        canvas.text(0,
                    (row + 2) * opts[:cell_height] + opts[:header_height],
                    opts[:row_header][row]).styles( :font_family  => opts[:font_family],
                                                    :font_size    => opts[:cell_height] * opts[:font_scale])
      end

      # drawing cells
      if opts[:gradient_mid_color]
        light_unit = opts[:max_val] == 0 ? 100.0 : 100.0 / (opts[:max_val] / 2.0)
      else
        light_unit = opts[:max_val] == 0 ? 50.0 : 50.0 / (opts[:max_val] - opts[:min_val])
      end

      0.upto(self.shape[0] - 1) do |col|
        0.upto(self.shape[1] - 1) do |row|
          # for log odds ratios
          if opts[:gradient_mid_color]
            if self[col, row] < 0
              color_fill = "hsl(120, 0, #{100 - self[col, row].abs * light_unit})"
            else
              color_fill = "hsl(0, 0, #{100 - self[col, row] * light_unit})"
            end
            canvas.rect(opts[:cell_width],
                        opts[:cell_height],
                        (col + 1) * opts[:cell_width],
                        (row + 1) * opts[:cell_height] + opts[:header_height]).styles(:fill         => color_fill,
                                                                                      :stroke       => 'white',
                                                                                      :stroke_width => opts[:cell_border])

          else
            canvas.rect(opts[:cell_width],
                        opts[:cell_height],
                        (col + 1) * opts[:cell_width],
                        (row + 1) * opts[:cell_height] + opts[:header_height]).styles(:fill         => "hsl(0, 100, #{100 - self[col, row] * light_unit})",
                                                                                      :stroke       => 'white',
                                                                                      :stroke_width => opts[:cell_border])
          end
          if opts[:print_values?]
            canvas.text((col + 1) * opts[:cell_width],
                        (row + 2) * opts[:cell_height] + opts[:header_height],
                     "#{'%.1f' % self[col, row]}").styles(:font_size => opts[:value_font_size])
          end
        end
      end

      # gradient key
      if opts[:gradient_mid_color]
        img1 = Image.new(opts[:gradient_height],
                         opts[:gradient_width] / 2,
                         GradientFill.new(0,
                                          opts[:gradient_width] / 2,
                                          opts[:gradient_height],
                                          opts[:gradient_width] / 2,
                                          opts[:gradient_start_color],
                                          opts[:gradient_mid_color])).rotate(90)

        img2 = Image.new(opts[:gradient_height],
                         opts[:gradient_width] / 2,
                         GradientFill.new(0,
                                          opts[:gradient_width] / 2,
                                          opts[:gradient_height],
                                          opts[:gradient_width] / 2,
                                          opts[:gradient_mid_color],
                                          opts[:gradient_end_color])).rotate(90)
        img3 = ImageList.new
        img3 << img1 << img2
        img = img3.append(false)

        img.border!(2, 2, 'black')

        gradient_x = (opts[:canvas_width] - opts[:gradient_width]) / 2
        gradient_y = opts[:header_height] + opts[:cell_height] * opts[:row_header].count + opts[:margin]

        canvas.image(img,
                    opts[:gradient_width],
                    opts[:gradient_height] + opts[:margin],
                    gradient_x,
                    gradient_y)
      else
        img = Image.new(opts[:gradient_height],
                        opts[:gradient_width],
                        GradientFill.new(0,
                                        opts[:gradient_width],
                                        opts[:gradient_height],
                                        opts[:gradient_width],
                                        opts[:gradient_start_color],
                                        opts[:gradient_end_color])).rotate(90)
        img.border!(2, 2, 'black')

        gradient_x = (opts[:canvas_width] - opts[:gradient_width]) / 2
        gradient_y = opts[:header_height] + opts[:cell_height] * opts[:row_header].count + opts[:margin]

        canvas.image(img,
                    opts[:gradient_width],
                    opts[:gradient_height] + opts[:margin],
                    gradient_x,
                    gradient_y)
      end

      canvas.text(gradient_x,
                  gradient_y + opts[:gradient_height] + opts[:margin],
                  "#{'%.1f' % opts[:min_val]}").styles(:font_size => opts[:key_font_size])

      canvas.text(gradient_x + opts[:gradient_width],
                  gradient_y + opts[:gradient_height] + opts[:margin],
                  "#{'%.1f' % opts[:max_val]}").styles(:font_size => opts[:key_font_size])
    end

    unless opts[:title].empty?
      rvg.draw.write("#{opts[:title]}.#{opts[:ext]}")
      $logger.info "Generating a heat map for #{opts[:title]} ..."
    else
      $logger.warn "A title for your matrix is not provided, so a object id, #{self.id} will be used for a file name."
      $logger.info "Generating a heat map for #{opts[:title]} ..."
      rvg.draw.write("#{self.id}.#{opts[:ext]}")
    end

    return true
  end
end

NMatrix.send(:include, NMatrixExtensions)
