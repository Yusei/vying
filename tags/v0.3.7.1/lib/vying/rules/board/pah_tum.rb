# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying/rules'

# Pah-Tum, sometimes written as POTM, provides an interesting twist on
# n-in-a-row games.  Instead of the game ending when a player achieves
# n-in-a-row, the game continues until the board is full, longer strings
# of pieces are worth more points and the winner is the player with the
# highest score at the end of the game.  The game also features random
# initial positions.
#
# For detailed rules see:  http://vying.org/games/pah_tum

class PahTum < Rules

  name    "Pah-Tum"
  version "1.0.0"

  players [:white, :black]

  random

  attr_reader :board, :unused_moves
  ignore :unused_moves

  def initialize( seed=nil )
    super

    w, h = 7, 7
    @board = Board.new( w, h )

    @unused_moves = @board.coords.to_a.dup
 
    num_blocks = [5,7,9,11,13][rand( 5 )]
    num_blocks.times do
      c = Coord[rand( w ), rand( h )] until c != nil && board[c].nil?
      board[c] = :x
      unused_moves.delete( c )
    end
  end

  def moves( player=nil )
    return [] unless player.nil? || has_moves.include?( player )

    unused_moves
  end

  def apply!( move )
    c = Coord[move]

    board[c] = turn
    unused_moves.delete( c )
    turn( :rotate )

    self
  end

  def final?
    unused_moves.empty?
  end

  def winner?( player )
    opp = player == :white ? :black : :white
    score( player ) > score( opp )
  end

  def loser?( player )
    opp = player == :white ? :black : :white
    score( player ) < score( opp )
  end

  def draw?
    score( :white ) == score( :black )
  end

  def score( player )
    in_a_row, score = 0, 0

    board.height.times do |y|
      c = Coord[0,y]
      score += pieces_score( player, board[*board.coords.row( c )] )
    end

    board.width.times do |x|
      c = Coord[x,0]
      score += pieces_score( player, board[*board.coords.column( c )] )
    end

    score
  end

  def hash
    [board,turn].hash
  end

  # How many points is a line of n-in-a-row worth?  
  #
  #   n < 3, score = 0
  #   n = 3, score = 3
  #   n > 3, score = 2 * score( n - 1 ) + n
  #

  def line_score( n )
    return 0 if n <  3
    return 3 if n == 3

    2 * line_score( n - 1 ) + n
  end

  # How many points for the given pieces (presumeably from a row or column).
  # The given pieces are assumed to be ordered and linear, as they appear
  # on the board.

  def pieces_score( player, pieces )
    in_a_row, score = 0, 0
    pieces.each do |p|
      if p == player
        in_a_row += 1
      else
        score += line_score( in_a_row )
        in_a_row = 0
      end
    end

    score + line_score( in_a_row )
  end



end
