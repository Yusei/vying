# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying/memoize'
require 'vying/board/coord'
require 'vying/board/boardext'

class Coords
  include Enumerable
  extend Memoizable

  class << self
    extend Memoizable
    memoize :new
  end

  attr_reader :width, :height, :coords
  protected :coords

  DIRECTIONS = { :n  => Coord.new( 0, -1 ),  :s  => Coord.new( 0, 1 ),
                 :w  => Coord.new( -1, 0 ),  :e  => Coord.new( 1, 0 ),
                 :nw => Coord.new( -1, -1 ), :ne => Coord.new( 1, -1 ),
                 :sw => Coord.new( -1, 1 ),  :se => Coord.new( 1, 1 ) }

  def initialize( w, h )
    @width = w
    @height = h
    @coords = Array.new( w*h ) { |i| Coord.new( i%w, i/w ) }.freeze
  end

  def each
    coords.each { |c| yield c }
  end

  def dup
    self
  end

  def to_a
    coords
  end

  def _dump( depth=-1 )
    Marshal.dump( [width, height] )
  end

  def self._load( str )
    width, height = Marshal.load( str )
    new( width, height )
  end

  def hash
    [width, height].hash
  end

  def group_by
    r, a = {}, []
    each do |c|
      y = yield c
      r[y] ||= a.size
      (a[r[y]] ||= []) << c
    end
    a
  end

  def row( coord )
    coords.select { |c| coord.y == c.y }
  end

  def rows
    column( Coord[0,0] ).map { |c| row( c ) }
  end

  def column( coord )
    coords.select { |c| coord.x == c.x }
  end

  def columns
    row( Coord[0,0] ).map { |c| column( c ) }
  end

  def diagonal( coord, slope=1 )
    coords.select { |c| slope*(coord.y-c.y) == (coord.x-c.x) }
  end

  def diagonals( slope=1 )
    cs = row( Coord[0,0] )
    cs += column( slope == 1 ? Coord[0,0] : Coord[width-1,0] )
    cs.uniq.map { |c| diagonal( c, slope ) }
  end

  def neighbors_nil( coord, directions=[:n,:ne,:e,:se,:s,:sw,:w,:nw] )
    a = directions.map { |dir| coord + DIRECTIONS[dir] }
    a.map { |c| (! include?( c )) ? nil : c }
  end

  def neighbors( coord, directions=[:n,:ne,:e,:se,:s,:sw,:w,:nw] )
    a = directions.map { |dir| coord + DIRECTIONS[dir] }
    a.reject! { |c| ! include?( c ) }
    a
  end

#  def next( coord, direction )
#    include?( n = coord + DIRECTIONS[direction] ) ? n : nil
#  end

  def radius( coord, r )
    directions=[:n,:ne,:e,:se,:s,:sw,:w,:nw]
    a = directions.map do |dir|
      sa, c, i = [], coord, 0
      while (c = self.next( c, dir )) && i < r
        sa << c
        i += 1
      end
      sa
    end 
    a.flatten!
    a.reject! { |c| ! include?( c ) }
    a
  end

  def ring( coord, d )
    coords.select do |c| 
      dx = (c.x - coord.x).abs
      dy = (c.y - coord.y).abs

      (dx == d && dy <= d) || (dx <= d && dy == d)
    end
  end

  def to_s
    inject( '' ) { |s,c| s + "#{c}" }
  end

  memoize :row
  memoize :column
  memoize :diagonal
  memoize :neighbors
  memoize :neighbors_nil
  memoize :ring
end

