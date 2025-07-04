# $gtk.reset

module Tetris
  class Game
    SPEEDS =                       [48, 42, 36, 30, 24,  18,  12,   9, 6].freeze
    SPEED_CHANGE_LINES_MILESTONES = [5, 20, 40, 60, 80, 100, 120, 140].freeze

    MIN_FRAMES_PER_MOVE = SPEEDS.last
    MAX_SPEED = SPEEDS.count - 1

    def initialize(args, start_speed: 1)
      @args = args
      @grid = Grid.new

      @speed = start_speed
      @frames_per_move = SPEEDS[@speed]
      @current_frame = 0
      @should_plant = false
      @planted_shape_just_now = false

      @kb = @args.inputs.keyboard
      @held_key_throttle_by = 0

      @lines = 0
      @score = 0
      @pause = false
      @game_over = false
      @should_reset = false

      @randomizer = Shape::TGMRandomizer.new

      spawn_shape
      spawn_shape
    end

    attr_reader :frames_per_move, :grid, :current_shape, :next_shape,
                :speed, :lines, :score

    def should_reset?
      @should_reset
    end

    def should_reset!
      @should_reset = true
    end

    def over?
      @game_over
    end

    def paused?
      @pause
    end

    def planted_shape_just_now?
      @planted_shape_just_now
    end

    def spawn_shape
      @current_shape = @next_shape
      @next_shape = Shape.new(@randomizer.deal, grid: @grid)
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
        @kb.key_down.enter && should_reset!
        return
      end

      if @kb.key_down.escape
        toggle_pause
      end
      return if @pause

      if @kb.key_down.up
        @current_shape.rotate && postpone_and_prevent_planting
      elsif @kb.key_down.left || (@kb.key_held.left && held_key_check)
        @current_shape.move_left && postpone_and_prevent_planting
        throttle_held_key(@kb.key_down.left)
      elsif @kb.key_down.right || (@kb.key_held.right && held_key_check)
        @current_shape.move_right && postpone_and_prevent_planting
        throttle_held_key(@kb.key_down.right)
      elsif @kb.key_down.down || (@kb.key_held.down && held_key_check)
        @current_shape.move_down && postpone_and_prevent_planting
        throttle_held_key(false)
      elsif @kb.key_down.space
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
      @planted_shape_just_now = false

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

      @planted_shape_just_now = true
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

    def tick
      iterate
    end
  end
end
