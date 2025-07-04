# $gtk.reset

require_relative "tetris"

def tick(args)
  args.state.game ||= new_game(args)
  args.state.game_renderer ||= new_game_renderer(args)

  if args.state.game.should_reset?
    args.state.game_renderer.cleanup!
    args.state.game = new_game(args)
    args.state.game_renderer = new_game_renderer(args)
  end

  args.state.game.tick
  args.state.game_renderer.render
  # args.outputs.primitives << args.gtk.framerate_diagnostics_primitives
end

def new_game(args)
  Tetris::Game.new(args)
end

def new_game_renderer(args)
  Tetris::GameRenderer.new(args, args.state.game)
end
