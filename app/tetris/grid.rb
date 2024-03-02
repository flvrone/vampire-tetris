module Tetris
  class Grid
    GRID_WIDTH = 10
    GRID_HEIGHT = 20

    BLANK_ROW = Array.new(GRID_WIDTH, 0).freeze

    def initialize
      @grid_array = Array.new(GRID_HEIGHT) { Array.new(GRID_WIDTH, 0) }
    end

    def width
      GRID_WIDTH
    end

    def height
      GRID_HEIGHT
    end

    def row(index)
      @grid_array[index] || BLANK_ROW
    end

    def cell(col, row)
      self.row(row)[col]
    end

    def cell_occupied?(col, row)
      cell(col, row) != 0
    end

    def cannot_plant_shape?(shape)
      shape.top_row >= height || shape.bottom_row < 0
    end

    def plant_shape(shape)
      shape.boxes.each do |b|
        real_row(b.row)[b.col] = b.color_index
      end
    end

    def real_row(index)
      @grid_array[index]
    end

    def row_filled?(index)
      real_row(index).all?(&:positive?)
    end

    def clear_row(index)
      deleted_row = @grid_array.delete_at(index)
      deleted_row.fill(0)
      @grid_array.push(deleted_row)
    end

    def clear_rows_at(idices)
      idices.sort.reverse_each do |index|
        clear_row(index)
      end
    end

    def rows_to_clear_with_shape(shape)
      rows_to_clear = []
      shape.rows_range.each.reverse_each do |row_index|
        rows_to_clear.push(row_index) if row_filled?(row_index)
      end

      rows_to_clear
    end

    def boxes
      @grid_array.flat_map.each_with_index do |grid_row, row_index|
        grid_row.filter_map.each_with_index do |color_index, col_index|
          next if color_index == 0

          Box.new(col_index, row_index, color_index)
        end
      end
    end
  end
end
