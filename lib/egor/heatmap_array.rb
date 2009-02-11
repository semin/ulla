require 'rubygems'
require 'RMagick'
require 'facets'

module Egor
  class HeatmapArray < Array

    include Magick

    def initialize
    end

    def heatmap(options = {})
      opts = {  :columns => 4,
                :rvg_width => nil,
                :max_val => 100,
                :min_val => 0
              }.merge(options)

      row_images = ImageList.new

      self.each_by(opts[:columns]) { |maps|
        images = ImageList.new
        maps.each { |m| images << m }
        row_images << images.append(false)
      }

      tbl_img     = row_images.append(true)
      rvg_width   = opts[:rvg_width] * opts[:columns]
      rvg_height  = rvg_width / 10.0

      rvg = RVG.new(rvg_width, rvg_height) do |canvas|
        canvas.viewbox(0, 0, rvg_width, rvg_height)
        canvas.background_fill = 'white'
        canvas.desc = 'gradient key'

        big_gradient_width = rvg_width / 2.0
        big_gradient_height = big_gradient_width / 15.0

        key_img = Image.new(big_gradient_width,
                            big_gradient_height,
                            GradientFill.new(0, 0, 0, big_gradient_width, '#FFFFFF', '#FF0000'))

        key_img.border!(1,1,'black')

        big_gradient_x = (rvg_width - big_gradient_width) / 2.0
        big_gradient_y = 5
        big_gradient_font_size = rvg_width / 50.0

        canvas.image(key_img,
                     big_gradient_width,
                     big_gradient_height,
                     big_gradient_x,
                     big_gradient_y)

        canvas.text(big_gradient_x,
                    big_gradient_y + big_gradient_height + big_gradient_font_size * 1.2,
                          "#{'%.1f' % opts[:min_val]}").styles(:font_size => big_gradient_font_size)

        canvas.text(big_gradient_x + big_gradient_width,
                    big_gradient_y + big_gradient_height + big_gradient_font_size * 1.2,
                          "#{'%.1f' % opts[:max_val]}").styles(:font_size => big_gradient_font_size)
      end

      fin_img = ImageList.new
      fin_img << tbl_img << rvg.draw
      fin_img.append(true)
    end
  end
end
