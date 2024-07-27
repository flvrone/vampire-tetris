# $gtk.reset

require_relative "tetris"

def tick(args)
  args.state.game ||= new_game(args)

  if args.state.game.should_reset?
    args.state.game = new_game(args)
  end

  args.state.game.tick
end

def new_game(args)
  Tetris::Game.new(args)
end
