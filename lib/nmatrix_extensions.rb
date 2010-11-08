<<<<<<< HEAD
begin
  require 'rvg/rvg'
  include Magick
rescue Exception => e
  $logger.warn "#{e.to_s.chomp} For this reason, heat maps cannot be generated."
  $no_rmagick = true
end

=======
>>>>>>> e5bd0d911ab38c672a1c0424fad4bf642468dbc4
module NMatrixExtensions

  def pretty_string(options={})
    opts = {:col_header => nil,
            :row_header => nil,
            :col_size   => 7}.merge(options)

    ("%-3s" % "#") + opts[:col_header].inject("") { |s, a|
      s + ("%#{opts[:col_size]}s" % a)
    } + "\n" + self.to_a.each_with_index.map { |a, i|
      ("%-3s" % opts[:row_header][i]) + a.inject("") { |s, v|
        if v.is_a? Float
          s + ("%#{opts[:col_size]}.2f" % v)
        else
          s + ("%#{opts[:col_size]}d" % v)
        end
      }
    }.join("\n")
  end

  def heatmap(options={})
    if $no_rmagick
      return nil
    end

    opts = {:col_header             => 'ACDEFGHIKLMNPQRSTVWYJ'.split(''),
            :row_header             => 'ACDEFGHIKLMNPQRSTVWYJ'.split(''),
            :max_val                => self.max,
            :mid_val                => (self.max - self.min) / 2.0,
            :min_val                => self.min,
            :dpi                    => 100,
            :margin_width           => 30,
            :rvg_width              => nil,
            :rvg_height             => nil,
            :canvas_width           => nil,
            :canvas_height          => nil,
            :cell_width             => 20,
            :cell_height            => 20,
            :cell_border_color      => '#888888',
            :cell_border_width      => 1,
            :table_border_color     => '#000000',
            :table_border_width     => 2,
            :header_height          => 100,
            :footer_height          => 50,
            :print_gradient         => true,
            :gradient_width         => 300,
            :gradient_height        => 30,
            :gradient_beg_color     => '#FFFFFF',
            :gradient_mid_color     => nil,
            :gradient_end_color     => '#FF0000',
            :gradient_border_width  => 1,
            :gradient_border_color  => '#000000',
            :font_scale             => 0.9,
            :font_family            => 'san serif',
            :small_gap_width        => 2,
            :title?                 => true,
            :title                  => '',
            :title_font_size        => 35,
            :title_font_scale       => 1.0,
            :print_value            => false,
            :key_font_size          => 15,
            :value_font_size        => 8,
            :background             => '#FFFFFF'}.merge(options)

    RVG::dpi = opts[:dpi]

    rvg = RVG.new(opts[:rvg_width], opts[:rvg_height]) do |canvas|
      title_x = (opts[:canvas_width] - opts[:title].length * opts[:title_font_size] * opts[:title_font_scale] / 2.0) / 2.0
      title_y = opts[:header_height] - opts[:title_font_size] * opts[:title_font_scale]

      canvas.viewbox(0, 0, opts[:canvas_width], opts[:canvas_height])
      canvas.background_fill = opts[:background]
      canvas.desc = opts[:title]

      if opts[:title?]
        canvas.text(title_x, title_y, opts[:title]).styles(:font_size => opts[:title_font_size] * opts[:title_font_scale])
      end

      # border for whole matrix
      table_x = (opts[:canvas_width] - opts[:cell_width] * self.shape[0]) / 2.0
      table_y = opts[:header_height] + opts[:cell_height]

      canvas.rect(self.shape[0] * opts[:cell_width],
                  self.shape[1] * opts[:cell_height],
                  table_x,
                  table_y).styles(:stroke       => opts[:table_border_color],
                                  :stroke_width => opts[:table_border_width])

      # drawing column and row labels
      0.upto(self.shape[0] - 1) do |col|
        canvas.text(table_x + col * opts[:cell_width] + opts[:small_gap_width],
                    opts[:cell_height] + opts[:header_height] - opts[:small_gap_width],
                    opts[:col_header][col]).styles( :font_family  => opts[:font_family],
                                                    :font_size    => opts[:cell_width] * opts[:font_scale])
      end

      0.upto(self.shape[1] - 1) do |row|
        canvas.text(table_x - opts[:cell_width],
                    table_y + (row + 1) * opts[:cell_height],
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
                      table_x + col * opts[:cell_width],
                      table_y + row * opts[:cell_height]).styles( :fill         => color,
                                                                  :stroke       => opts[:cell_border_color],
                                                                  :stroke_width => opts[:cell_border_width])

          if opts[:print_value]
            canvas.text(table_x + col * opts[:cell_width] + opts[:cell_border_width],
                        table_y + (row + 1) * opts[:cell_height],
                        "#{'%.1f' % self[col, row]}").styles(:font_size => opts[:value_font_size])
          end
        end
      end

      # gradient key
      if opts[:print_gradient]
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

        img.border!(opts[:gradient_border_width],
                    opts[:gradient_border_width],
                    opts[:gradient_border_color])

        gradient_x = (opts[:canvas_width] - opts[:gradient_width]) / 2
        gradient_y = opts[:header_height] + opts[:cell_height] * opts[:row_header].count + opts[:margin_width]

        canvas.image(img,
                    opts[:gradient_width],
                    opts[:gradient_height] + opts[:margin_width],
                    gradient_x,
                    gradient_y)

        canvas.text(gradient_x,
                    gradient_y + opts[:gradient_height] + opts[:key_font_size] * 2,
                    "#{'%.1f' % opts[:min_val]}").styles(:font_size => opts[:key_font_size])

        canvas.text(gradient_x + opts[:gradient_width],
                    gradient_y + opts[:gradient_height] + opts[:key_font_size] * 2,
                    "#{'%.1f' % opts[:max_val]}").styles(:font_size => opts[:key_font_size])
      end
    end

    rvg.draw
  end


  private

  def interpolate(start_val, end_val, step, no_steps)
    begin
      if (start_val < end_val)
        ((end_val - start_val) / no_steps.to_f) * step + start_val
      else
        start_val - ((start_val - end_val) / no_steps.to_f) * step
      end.round
    rescue FloatDomainError
      start_val
    end
  end

end

NMatrix.send(:include, NMatrixExtensions)
