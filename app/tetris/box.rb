module Tetris
  class Box
    def initialize(col, row, color_index)
      @col = col
      @row = row
      @color_index = color_index
    end

    attr_reader :col, :row, :color_index
  end
end
