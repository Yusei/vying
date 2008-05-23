# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying/rules'

class YGroup
  attr_reader :coords, :sides, :size

  def initialize( size, c=nil )
    @coords, @sides, @size = [], 0, size
    self << c if c
  end

  def winning?
    sides == 7
  end

  def |( group )
    g = YGroup.new( size )
    g.instance_variable_set( "@coords", coords | group.coords )
    g.instance_variable_set( "@sides",  sides  | group.sides )
    g
  end

  def <<( c )
    coords << c
    @sides |= 1  if c.x == 0
    @sides |= 2  if c.y == 0
    @sides |= 4  if c.x + c.y == size - 1
  end
end

# Y
#
# For detailed rules see:  http://vying.org/games/y

class Y < Rules

  name    "Y"
  version "0.0.1"

  players [:blue, :red]

  attr_reader :board, :groups

  def initialize( seed=nil )
    super

    @board = YBoard.new
    @groups = { :blue => [], :red => [] }
  end

  def moves( player=nil )
    return []          unless player.nil? || has_moves.include?( player )

    board.unoccupied
  end

  def apply!( move )
    coord = Coord[move]

    board[coord] = turn

    new_groups = []
    YBoard::DIRECTIONS.each do |d|
      n = board.coords.next( coord, d )

      groups[turn].delete_if do |g|
        if g.coords.include?( n )
          g << coord
          new_groups << g
        end
      end
    end

    if new_groups.empty?
      groups[turn] << YGroup.new( board.width, coord )
    else
      g = YGroup.new( board.width )
      groups[turn] << new_groups.inject( g ) { |m,a| m | a }
    end

    turn( :rotate )

    self
  end

  def final?
    players.any? { |p| winner?( p ) }
  end

  def winner?( player )
    groups[player].any? { |group| group.winning? }
  end

  def loser?( player )
    opp = player == :blue ? :red : :blue
    winner?( opp )
  end

  def hash
    [board,turn].hash
  end
end

