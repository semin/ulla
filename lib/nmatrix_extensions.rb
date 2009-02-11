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
            :margin_width         => 70,
            :rvg_width            => 1200,
            :rvg_height           => 1400,
            :canvas_width         => 900,
            :canvas_height        => 1200,
            :cell_width           => 40,
            :cell_height          => 40,
            :cell_border_color    => '#FFFFFF',
            :cell_border_width    => 1,
            :table_border_color   => '#000000',
            :table_border_width   => 4,
            :header_height        => 100,
            :footer_height        => 100,
            :gradient_width       => 600,
            :gradient_height      => 60,
            :gradient_beg_color => '#FFFFFF',
            :gradient_mid_color   => nil,
            :gradient_end_color   => '#FF0000',
            :font_scale           => 0.9,
            :font_family          => 'san serif',
            :small_gap_width      => 4,
            :title?               => true,
            :title                => '',
            :title_font_size      => 50,
            :print_values?        => true,
            :key_font_size        => 30,
            :value_font_size      => 15,
            :background           => '#FFFFFF',
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
                  opts[:cell_height] + opts[:header_height]).styles(:stroke => opts[:table_border_color],
                                                                    :stroke_width => opts[:table_border_width])

      # drawing column and row labels
      0.upto(self.shape[0] - 1) do |col|
        canvas.text((col + 1) * opts[:cell_width] + opts[:small_gap_width],
                    opts[:cell_height] + opts[:header_height] - opts[:small_gap_width],
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

      # calculating a unit of RGB color in a decimal number
      r_beg = (opts[:gradient_beg_color].rgb_to_integer & 0xFF0000) >> 16
      g_beg = (opts[:gradient_beg_color].rgb_to_integer & 0x00FF00) >> 8
      b_beg = (opts[:gradient_beg_color].rgb_to_integer & 0x0000FF) >> 0
      r_end = (opts[:gradient_end_color].rgb_to_integer & 0xFF0000) >> 16
      g_end = (opts[:gradient_end_color].rgb_to_integer & 0x00FF00) >> 8
      b_end = (opts[:gradient_end_color].rgb_to_integer & 0x0000FF) >> 0
      gap   = opts[:max_val] - opts[:min_val]

      if opts[:gradient_mid_color]
        r_mid = (opts[:gradient_mid_color].rgb_to_integer & 0xFF0000) >> 16
        g_mid = (opts[:gradient_mid_color].rgb_to_integer & 0x00FF00) >> 8
        b_mid = (opts[:gradient_mid_color].rgb_to_integer & 0x0000FF) >> 0
        gap1  = opts[:mid_val] - opts[:min_val]
        gap2  = opts[:max_val] - opts[:mid_val]
      end

      0.upto(self.shape[0] - 1) do |col|
        0.upto(self.shape[1] - 1) do |row|
          if opts[:gradient_mid_color]
            if self[col, row] <= opts[:mid_val]
              r = interpolate(r_beg, r_mid, self[col, row] - opts[:min_val], gap1)
              g = interpolate(g_beg, g_mid, self[col, row] - opts[:min_val], gap1)
              b = interpolate(b_beg, b_mid, self[col, row] - opts[:min_val], gap1)
            else
              r = interpolate(r_mid, r_end, self[col, row] - opts[:mid_val], gap2)
              g = interpolate(g_mid, g_end, self[col, row] - opts[:mid_val], gap2)
              b = interpolate(b_mid, b_end, self[col, row] - opts[:mid_val], gap2)
            end
          else
            r = interpolate(r_beg, r_end, self[col, row] - opts[:min_val], gap)
            g = interpolate(g_beg, g_end, self[col, row] - opts[:min_val], gap)
            b = interpolate(b_beg, b_end, self[col, row] - opts[:min_val], gap)
          end

          color = ("#%6X" % ((((r << 8) | g) << 8) | b)).gsub(" ", "0")

          canvas.rect(opts[:cell_width],
                      opts[:cell_height],
                      (col + 1) * opts[:cell_width],
                      (row + 1) * opts[:cell_height] + opts[:header_height]).styles(:fill         => color,
                                                                                    :stroke       => opts[:cell_border_color],
                                                                                    :stroke_width => opts[:cell_border_width])

          if opts[:print_values?]
            canvas.text((col + 1) * opts[:cell_width] + opts[:cell_border_width],
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
                                          opts[:gradient_beg_color],
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
      else
        img = Image.new(opts[:gradient_height],
                        opts[:gradient_width],
                        GradientFill.new(0,
                                        opts[:gradient_width],
                                        opts[:gradient_height],
                                        opts[:gradient_width],
                                        opts[:gradient_beg_color],
                                        opts[:gradient_end_color])).rotate(90)
      end

      img.border!(2, 2, 'black')

      gradient_x = (opts[:canvas_width] - opts[:gradient_width]) / 2
      gradient_y = opts[:header_height] + opts[:cell_height] * opts[:row_header].count + opts[:margin_width]

      canvas.image(img,
                   opts[:gradient_width],
                   opts[:gradient_height] + opts[:margin_width],
                   gradient_x,
                   gradient_y)

      canvas.text(gradient_x,
                  gradient_y + opts[:gradient_height] + opts[:margin_width],
                  "#{'%.1f' % opts[:min_val]}").styles(:font_size => opts[:key_font_size])

      canvas.text(gradient_x + opts[:gradient_width],
                  gradient_y + opts[:gradient_height] + opts[:margin_width],
                  "#{'%.1f' % opts[:max_val]}").styles(:font_size => opts[:key_font_size])
    end

    unless opts[:title].empty?
      $logger.info "Generating a heat map for #{opts[:title]} ..."
      rvg.draw.write("#{opts[:title]}.#{opts[:ext]}")
    else
      $logger.warn "A title for your matrix is not provided, so a object id, #{self.id} will be used for a file name."
      $logger.info "Generating a heat map for #{opts[:title]} ..."
      rvg.draw.write("#{self.id}.#{opts[:ext]}")
    end

    return true
  end


  private

  def interpolate(start_val, end_val, step, no_steps)
    if (start_val < end_val)
      ((end_val - start_val) / no_steps.to_f) * step + start_val
    else
      start_val - ((start_val - end_val) / no_steps.to_f) * step
    end.round
  end

end

NMatrix.send(:include, NMatrixExtensions)
