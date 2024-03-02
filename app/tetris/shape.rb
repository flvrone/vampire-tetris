module Tetris
  class Shape
    J_BLOCK = [
      [1, 0, 0].freeze,
      [1, 1, 1].freeze
    ].reverse!.freeze
    I_BLOCK = [
      [2, 2, 2, 2].freeze
    ].freeze
    S_BLOCK = [
      [0, 3, 3].freeze,
      [3, 3, 0].freeze
    ].reverse!.freeze
    O_BLOCK = [
      [4, 4].freeze,
      [4, 4].freeze
    ].freeze
    L_BLOCK = [
      [0, 0, 5].freeze,
      [5, 5, 5].freeze
    ].reverse!.freeze
    Z_BLOCK = [
      [6, 6, 0].freeze,
      [0, 6, 6].freeze
    ].reverse!.freeze
    T_BLOCK = [
      [0, 7, 0].freeze,
      [7, 7, 7].freeze
    ].reverse!.freeze

    SHAPES = [
      J_BLOCK, I_BLOCK, S_BLOCK, O_BLOCK, L_BLOCK, Z_BLOCK, T_BLOCK
    ].freeze

    S_INDEX = SHAPES.index(S_BLOCK)
    Z_INDEX = SHAPES.index(Z_BLOCK)

    # https://tetris.fandom.com/wiki/TGM_randomizer
    class TGMRandomizer
      def initialize(shapes = SHAPES, initial_history = [Z_INDEX, Z_INDEX, S_INDEX, S_INDEX])
        @shapes = shapes
        @count = shapes.count
        @history = initial_history
      end

      def deal
        @history.unshift(generate_index)
        @history.pop

        @shapes[@history.first]
      end

      def generate_index
        index = rand(@count)
        5.times do
          return index if !@history.include?(index)

          index = rand(@count)
        end

        index
      end
    end

    class Projection
      def initialize(shape)
        @shape = shape
      end

      def boxes
        @boxes ||= @shape.boxes(row: @shape.projection_bottom_row)
      end

      def reset
        @boxes = nil
      end
    end

    class PositionedProjection
      def initialize(shape, col:, row:)
        @shape = shape
        @col = col
        @row = row
      end

      def boxes
        @boxes ||= @shape.boxes(col: @col, row: @row)
      end
    end

    def initialize(shape_array, col = nil, row = nil, grid:)
      @shape_array = shape_array
      @grid = grid
      @col = col || ((grid.width / 2) - (width / 2)).floor
      @row = row || grid.height
      @projection = Projection.new(self)

      @state = 0
    end

    attr_reader :row, :col, :projection
    alias_method :bottom_row, :row
    alias_method :left_col, :col

    def top_row
      bottom_row + height - 1
    end

    def right_col
      left_col + width - 1
    end

    def width
      @shape_array[0].length
    end

    def height
      @shape_array.length
    end

    def rows_range
      bottom_row..top_row
    end

    def move_left
      return false unless can_be_placed_on?(col: col - 1)

      reset_projection
      @col -= 1
      true
    end

    def move_right
      return false unless can_be_placed_on?(col: col + 1)

      reset_projection
      @col += 1
      true
    end

    def move_down
      return false if cannot_descend?

      descend
      true
    end

    # clockwise
    def rotate
      return false unless _rotate

      reset_projection
      @state = @state >= 3 ? 0 : @state + 1

      true
    end

    def _rotate
      prev_shape_array = @shape_array
      @shape_array = @shape_array.transpose.reverse!

      # I_BLOCK
      if height == 4
        if @state == 0
          if can_be_placed_on?(col: col + 1)
            @col += 1
            return true
          end
        end
        if @state == 2
          if can_be_placed_on?(col: col + 2)
            @col += 2
            return true
          end
        end
      end
      if width == 4
        if @state == 1
          if can_be_placed_on?(col: col - 1)
            @col -= 1
            return true
          end
        end
        if @state == 3
          if can_be_placed_on?(col: col - 2)
            @col -= 2
            return true
          end
        end
      end

      return true if can_be_placed_on?

      horizonal_shift = (width / 2).floor
      vertical_shift = (height / 2).floor

      shift = horizonal_shift
      shift = vertical_shift if vertical_shift > shift

      if can_be_placed_on?(col: col + shift)
        @col += shift
        return true
      end

      # I_BLOCK
      if shift != 1
        if can_be_placed_on?(col: col - 1)
          @col -= 1
          return true
        end
      end

      if can_be_placed_on?(col: col - shift)
        @col -= shift
        return true
      end

      if can_be_placed_on?(row: row + shift)
        @row += shift
        return true
      end

      # I_BLOCK
      if shift == 2
        shift = 3

        if can_be_placed_on?(col: col - shift)
          @col -= shift
          return true
        end

        # climbing?
        if can_be_placed_on?(row: row + shift)
          @row += shift
          return true
        end
      end

      # climbing?
      if shift == 1
        shift = 2
        if can_be_placed_on?(row: row + shift)
          @row += shift
          return true
        end
      end

      @shape_array = prev_shape_array
      false
    end

    def can_be_placed_on?(col: @col, row: @row)
      return false if col < 0 || (col + width - 1 >= @grid.width) || row < 0

      boxes(col: col, row: row).none? do |b|
        @grid.cell_occupied?(b.col, b.row)
      end
    end

    def can_descend?
      can_be_placed_on?(row: row - 1)
    end

    def cannot_descend?
      !can_descend?
    end

    def descend
      @row -= 1
    end

    def drop
      @row = projection_bottom_row
    end

    def find_projection_bottom_row
      return row if row <= 0

      projection_row = row - 1
      while can_be_placed_on?(row: projection_row) do
        projection_row -= 1
      end

      projection_row + 1
    end

    def projection_bottom_row
      @projection_bottom_row ||= find_projection_bottom_row
    end

    def reset_projection
      @projection_bottom_row = nil
      projection.reset
    end

    def positioned_projection(col:, row:)
      PositionedProjection.new(self, col: col, row: row)
    end

    def boxes(col: @col, row: @row)
      @shape_array.flat_map.each_with_index do |shape_row, row_index|
        shape_row.filter_map.each_with_index do |color_index, col_index|
          next if color_index == 0

          Box.new(col + col_index, row + row_index, color_index)
        end
      end
    end
  end
end
