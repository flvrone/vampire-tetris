# $gtk.reset

module Tetris
  class Game
    SPEEDS =                       [48, 42, 36, 30, 24,  18,  12,   9, 6].freeze
    SPEED_CHANGE_LINES_MILESTONES = [5, 20, 40, 60, 80, 100, 120, 140].freeze

    MIN_FRAMES_PER_MOVE = SPEEDS.last
    MAX_SPEED = SPEEDS.count - 1

    def initialize(args, grid_x: nil, grid_y: nil, box_size: 26, start_speed: 1)
      @args = args
      @grid = Grid.new

      @box_size = box_size
      @grid_x = grid_x || (1280 - @box_size * @grid.width) / 2
      @grid_y = grid_y || (720 - @box_size * (@grid.height + 1)) / 2

      @speed = start_speed
      @frames_per_move = SPEEDS[@speed]
      @current_frame = 0
      @should_plant = false

      @kb = @args.inputs.keyboard
      @held_key_throttle_by = 0

      @lines = 0
      @score = 0
      @pause = false
      @game_over = false

      @randomizer = Shape::TGMRandomizer.new

      spawn_shape
      spawn_shape
    end

    attr_reader :frames_per_move

    def out
      @args.outputs
    end

    def background
      # out.solids << {x: 0, y: 0, w: 1280, h: 720, **BACKGROUND}
      out.background_color = BACKGROUND

      (-1..@grid.width).each do |col|
        box_in_grid(col, -1, FRAME)
        box_in_grid(col, @grid.height, FRAME)
      end

      (0...@grid.height).each do |row|
        box_in_grid(-1, row, FRAME)
        box_in_grid(@grid.width, row, FRAME)
      end
    end

    def render_boxes(box_collection, **opts)
      box_collection.each_box do |col, row, color_index|
        box_in_grid(col, row, COLORS_INDEX[color_index], **opts)
      end
    end

    def grid_cell_coordinates(col, row)
      {
        x: @grid_x + col * @box_size,
        y: @grid_y + row * @box_size
      }
    end

    def box_in_grid(col, row, color, solid: true)
      x, y = grid_cell_coordinates(col, row).values
      solid ? box(x, y, color) : box_border(x, y, color)
    end

    def box(x, y, color, padding: 2)
      padded_size = @box_size - (padding * 2)
      out.solids << {
        x: x + padding, y: y + padding,
        w: padded_size, h: padded_size,
        **color
      }
    end

    def box_border(x, y, color, padding: 2)
      padded_size = @box_size - (padding * 2)
      out.borders << {
        x: x + padding, y: y + padding,
        w: padded_size, h: padded_size,
        **color
      }
      out.borders << {
        x: x + padding + 1, y: y + padding + 1,
        w: padded_size - 2, h: padded_size - 2,
        **color
      }
    end

    def spawn_shape
      @current_shape = @next_shape
      @next_shape = Shape.new(@randomizer.deal, grid: @grid)
      @next_shape_projection = nil
    end

    def throttle_held_key(key_down)
      @held_key_throttle_by = key_down ? 9 : 3
    end

    def held_key_check
      @held_key_throttle_by -= 1

      @held_key_throttle_by <= 0
    end

    def toggle_pause
      @pause = !@pause
    end

    def handle_input
      if @game_over
        @kb.key_down.enter && $gtk.reset
        return
      end

      if @kb.key_down.escape
        toggle_pause
      end
      return if @pause

      if @kb.key_down.up
        @current_shape.rotate && postpone_and_prevent_planting
      end
      if @kb.key_down.left || (@kb.key_held.left && held_key_check)
        @current_shape.move_left && postpone_and_prevent_planting
        throttle_held_key(@kb.key_down.left)
      end
      if @kb.key_down.right || (@kb.key_held.right && held_key_check)
        @current_shape.move_right && postpone_and_prevent_planting
        throttle_held_key(@kb.key_down.right)
      end
      if @kb.key_down.down || (@kb.key_held.down && held_key_check)
        @current_shape.move_down && postpone_and_prevent_planting
        throttle_held_key(false)
      end
      if @kb.key_down.space
        @current_shape.drop && hasten_planting
      end
    end

    def hasten_planting
      @should_plant = true
      @current_frame = frames_per_move
    end

    def postpone_planting(by = 9 + @speed)
      return unless @should_plant

      new_frame = frames_per_move - by
      @current_frame > new_frame && @current_frame = new_frame
    end

    def force_postpone_planting
      @current_frame = frames_per_move
      postpone_planting
    end

    def prevent_planting
      @should_plant = false
    end

    def postpone_and_prevent_planting
      postpone_planting
      prevent_planting
    end

    def iterate
      handle_input
      return if @pause || @game_over

      game_move
    end

    def game_move
      @current_frame += 1
      return if @current_frame < frames_per_move

      @current_frame = 0

      if @current_shape.can_descend?
        @current_shape.descend
        return
      end

      unless @should_plant
        @should_plant = true
        force_postpone_planting
        return
      end

      if @grid.cannot_plant_shape?(@current_shape)
        @game_over = true
        return
      end

      plant_shape
    end

    def plant_shape
      @grid.plant_shape(@current_shape)

      rows_to_clear = @grid.rows_to_clear_with_shape(@current_shape)
      @grid.clear_rows_at(rows_to_clear)
      @lines += rows_to_clear.count
      @score += rows_to_clear.count**2

      prevent_planting
      spawn_shape

      speed_up_game
    end

    def speed_up_game
      return if @frames_per_move <= MIN_FRAMES_PER_MOVE
      return if @lines < SPEED_CHANGE_LINES_MILESTONES[@speed]

      @speed += 1
      @frames_per_move = SPEEDS[@speed]
    end

    def render
      background

      render_boxes(@grid)
      render_boxes(@current_shape)
      return render_game_over if @game_over

      render_speed
      render_score
      render_next_shape
      return render_pause if @pause

      render_boxes(@current_shape.projection, solid: false)
    end

    def tick
      iterate
      render
    end

    def render_speed
      @speed_label ||= {
        **grid_cell_coordinates(-5.5, 21),
        **WHITE
      }
      speed_title = (@speed == MAX_SPEED ? "MAX" : @speed)
      out.labels << {**@speed_label, text: "Speed: #{speed_title}"}
    end

    def render_score
      @lines_label ||= {
        **grid_cell_coordinates(-5.5, 20),
        **WHITE
      }
      @score_label ||= {
        **grid_cell_coordinates(-5.5, 19),
        **WHITE
      }
      out.labels << {**@lines_label, text: "Lines: #{@lines}"}
      out.labels << {**@score_label, text: "Score: #{@score}"}
    end

    def render_next_shape
      @next_shape_projection ||= @next_shape.positioned_projection(col: 12, row: 19)
      render_boxes(@next_shape_projection)
    end

    def render_pause
      render_overlay
      @pause_label ||= {
        **grid_cell_coordinates(5, 13),
        text: "Paused",
        size_enum: 28,
        alignment_enum: 1,
        **WHITE
      }
      out.labels << @pause_label
    end

    def render_game_over
      render_overlay
      @game_over_label ||= {
        **grid_cell_coordinates(5, 16),
        text: "Game Over",
        size_enum: 40,
        alignment_enum: 1,
        **WHITE
      }
      @game_over_score_label ||= {
        **grid_cell_coordinates(5, 11.5),
        size_enum: 10,
        alignment_enum: 1,
        **WHITE
      }
      @game_over_lines_label ||= {
        **grid_cell_coordinates(5, 9.5),
        size_enum: 10,
        alignment_enum: 1,
        **WHITE
      }
      @game_over_restart_label ||= {
        **grid_cell_coordinates(5, 6.75),
        text: "Press `Enter` to restart",
        size_enum: 8,
        alignment_enum: 1,
        **WHITE
      }
      out.labels << @game_over_label
      out.labels << {**@game_over_score_label, text: "Your score: #{@score}"}
      out.labels << {**@game_over_lines_label, text: "Lines cleared: #{@lines}"}
      out.labels << @game_over_restart_label
    end

    def render_overlay
      @overlay_solid ||= {
        x: @grid_x - @box_size,
        y: @grid_y - @box_size,
        w: 12 * @box_size,
        h: 25 * @box_size,
        **BACKGROUND, a: 240
      }

      out.solids << @overlay_solid
    end
  end
end
