require 'rubygems'
require 'facets'

begin
  require 'RMagick'
  include Magick
rescue Exception => e
  $logger.warn "#{e.to_s.chomp} For this reason, heat maps cannot be generated."
  $no_rmagick = true
end



module Ulla
  class HeatmapArray < Array

    def heatmap(options = {})
      if $no_rmagick
        return nil
      end

      opts = {:columns                => 4,
              :rvg_width              => nil,
              :dpi                    => 100,
              :title                  => '',
              :max_val                => nil,
              :mid_val                => nil,
              :min_val                => nil,
              :print_gradient         => true,
              :gradient_beg_color     => '#FFFFFF',
              :gradient_mid_color     => nil,
              :gradient_end_color     => '#FF0000',
              :gradient_border_width  => 1,
              :gradient_border_color  => '#000000'}.merge(options)

      row_images = ImageList.new

      self.each_by(opts[:columns]) { |maps|
        images = ImageList.new
        maps.each { |m| images << m }
        row_images << images.append(false)
      }

      tbl_img = row_images.append(true)

      unless opts[:print_gradient]
        return tbl_img
      else
        RVG::dpi    = opts[:dpi]
        rvg_width   = opts[:rvg_width] * opts[:columns]
        rvg_height  = rvg_width / 10.0

        rvg = RVG.new(rvg_width, rvg_height) do |canvas|
          canvas.viewbox(0, 0, rvg_width, rvg_height)
          canvas.background_fill = 'white'
          canvas.desc = 'gradient key'

          gradient_width = rvg_width / 2.0
          gradient_height = gradient_width / 15.0

          if opts[:gradient_mid_color]
            img1  = Image.new(gradient_width / 2,
                              gradient_height,
                              GradientFill.new(0, 0, 0, gradient_width / 2,
                                               opts[:gradient_beg_color], opts[:gradient_mid_color]))

            img2  = Image.new(gradient_width / 2,
                              gradient_height,
                              GradientFill.new(0, 0, 0, gradient_width / 2,
                                               opts[:gradient_mid_color], opts[:gradient_end_color]))

            img3  = ImageList.new
            img3  << img1 << img2
            img   = img3.append(false)
          else
            img = Image.new(gradient_width,
                            gradient_height,
                            GradientFill.new(0, 0, 0, gradient_width,
                                             opts[:gradient_beg_color], opts[:gradient_end_color]))
          end

          img.border!(opts[:gradient_border_width],
                      opts[:gradient_border_width],
                      opts[:gradient_border_color])

          gradient_x = (rvg_width - gradient_width) / 2.0
          gradient_y = (rvg_height - gradient_height) / 2.0
          gradient_font_size = rvg_width / 45.0

          canvas.image(img,
                       gradient_width,
                       gradient_height,
                       gradient_x,
                       gradient_y)

          canvas.text(gradient_x,
                      gradient_y + gradient_height + gradient_font_size * 1.1,
                      "#{'%.1f' % opts[:min_val]}").styles(:font_size => gradient_font_size)

          canvas.text(gradient_x + gradient_width,
                      gradient_y + gradient_height + gradient_font_size * 1.1,
                      "#{'%.1f' % opts[:max_val]}").styles(:font_size => gradient_font_size)
        end

        fin_img = ImageList.new
        fin_img << tbl_img << rvg.draw
        fin_img.append(true)
      end
    end
  end
end
