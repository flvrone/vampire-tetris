module Tetris
  class GameRenderer
    def initialize(args, game, grid_x: nil, grid_y: nil, box_size: 26)
      @args = args
      @game = game
      @grid = game.grid

      @box_size = box_size
      @grid_x = grid_x || (args.grid.w - @box_size * @grid.width) / 2
      @grid_y = grid_y || (args.grid.h - @box_size * (@grid.height + 6))
      @box_renderer = BoxRenderer.new(size: @box_size)
    end

    attr_reader :game, :grid

    def out
      @args.outputs
    end

    def cleanup!
      out.clear
    end

    def background
      # out.solids << {x: 0, y: 0, w: args.grid.w, h: args.grid.h, **BACKGROUND}
      out.background_color = BACKGROUND
    end

    def box_in_grid(col, row, color_i = 0)
      @box_renderer.sprite(**grid_cell_coordinates(col, row), color_i: color_i)
    end

    def box_border_in_grid(col, row, color_i = 0)
      @box_renderer.borders(**grid_cell_coordinates(col, row), color_i: color_i)
    end

    def frame_boxes
      @frame_boxes ||= (0...grid.width).map do |col|
        box_in_grid(col, grid.height)
      end
    end

    def render_static_frame_boxes
      return if @static_frame_rendered

      out.static_sprites <<
        (0...grid.width)
        .map { |col| box_in_grid(col, -1) }
        .concat(
          (0...grid.height).flat_map do |row|
            [
              box_in_grid(-1, row),
              box_in_grid(grid.width, row)
            ]
          end
        )

      @static_frame_rendered = true
    end

    def grid_cell_coordinates(col, row)
      {
        x: @grid_x + col * @box_size,
        y: @grid_y + row * @box_size
      }
    end

    def render_overlay
      @overlay_sprite ||= {
        path: :solid,
        x: @grid_x - @box_size,
        y: @grid_y - @box_size,
        w: (grid.width + 2) * @box_size,
        h: (grid.height + 5) * @box_size,
        primitive_marker: :sprite,
        **BACKGROUND, a: 240
      }

      out.primitives << @overlay_sprite
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
      out.labels << [
        @game_over_label,
        {**@game_over_score_label, text: "Your score: #{game.score}"},
        {**@game_over_lines_label, text: "Lines cleared: #{game.lines}"},
        @game_over_restart_label
      ]
    end

    def render_stats
      @speed_label ||= {
        **grid_cell_coordinates(-6, 21),
        **WHITE
      }
      @lines_label ||= {
        **grid_cell_coordinates(-6, 20),
        **WHITE
      }
      @score_label ||= {
        **grid_cell_coordinates(-6, 19),
        **WHITE
      }
      speed_title = (game.speed == Game::MAX_SPEED ? "MAX" : game.speed)
      out.labels << [
        {**@speed_label, text: "Speed: #{speed_title}"},
        {**@lines_label, text: "Lines: #{game.lines}"},
        {**@score_label, text: "Score: #{game.score}"}
      ]
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

    def box_borders_in_grid(box_collection)
      box_collection.boxes.flat_map do |b|
        box_border_in_grid(b.col, b.row, b.color_index)
      end
    end

    def boxes_in_grid(box_collection)
      box_collection.boxes.map do |b|
        box_in_grid(b.col, b.row, b.color_index)
      end
    end

    def grid_boxes
      @grid_boxes ||= boxes_in_grid(grid)
    end

    def reset_grid_boxes
      @grid_boxes = nil
    end

    def next_shape_boxes
      @next_shape_boxes ||= boxes_in_grid(
        game.next_shape.positioned_projection(
          col: grid.width + 2,
          row: grid.height - 1
        )
      )
    end

    def reset_next_shape_boxes
      @next_shape_boxes = nil
    end

    def render
      background
      render_static_frame_boxes

      if game.planted_shape_just_now?
        reset_grid_boxes
        reset_next_shape_boxes
      end

      out.sprites << frame_boxes
      out.sprites << grid_boxes
      out.sprites << boxes_in_grid(game.current_shape)
      return render_game_over if game.over?

      render_stats
      return render_pause if game.paused?

      out.sprites << next_shape_boxes
      out.borders << box_borders_in_grid(game.current_shape.projection)
    end
  end
end
