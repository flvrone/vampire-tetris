module Tetris
  class BoxRenderer
    def initialize(size: 26, padding: 2, color_palette: COLORS_INDEX)
      @size = size
      @padding = padding
      @padded_size = size - (padding * 2)
      @color_palette = color_palette
    end

    attr_reader :size, :padding, :padded_size, :color_palette

    def sprite(x:, y:, color_i: nil)
      color = (color_i && color_palette[color_i]) || color_palette[0]
      {
        path: :solid,
        x: x + padding, y: y + padding,
        w: padded_size, h: padded_size,
        **color
      }
    end

    def borders(x:, y:, color_i: nil)
      color = (color_i && color_palette[color_i]) || color_palette[0]
      [
        {
          x: x + padding, y: y + padding,
          w: padded_size, h: padded_size,
          **color
        },
        {
          x: x + padding + 1, y: y + padding + 1,
          w: padded_size - 2, h: padded_size - 2,
          **color
        }
      ]
    end
  end
end
