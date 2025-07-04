# $gtk.reset

module Tetris
  BACKGROUND = {r: 34, g: 33, b: 44}.freeze
  FRAME = {r: 59, g: 58, b: 67}.freeze
  WHITE = {r: 245, g: 245, b: 239}.freeze

  BLUE = {r: 40, g: 194, b: 255}.freeze
  GREEN = {r: 138, g: 255, b: 128}.freeze
  PINK = {r: 255, g: 128, b: 191}.freeze
  YELLOW = {r: 255, g: 255, b: 128}.freeze
  PEACH = {r: 255, g: 149, b: 128}.freeze
  CYAN = {r: 128, g: 255, b: 234}.freeze
  VIOLET = {r: 149, g: 128, b: 255}.freeze

  COLORS_INDEX = [
    FRAME,
    BLUE,
    CYAN,
    GREEN,
    YELLOW,
    PEACH,
    PINK,
    VIOLET,
    WHITE
  ].freeze
end

require_relative "tetris/box"
require_relative "tetris/grid"
require_relative "tetris/shape"
require_relative "tetris/game"
require_relative "tetris/box_renderer"
require_relative "tetris/game_renderer"
