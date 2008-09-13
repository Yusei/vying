# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.


class Board

  SHAPES = [:square, :rect, :rhombus, :triangle, :hexagon].freeze

  attr_reader :shape, :cell_shape, :coords, :cells, 
              :width, :height, :length, :occupied, :plugins
  protected :cells

  prototype

  # Initialize a board.  Accepts a hash with the following parameters:
  #
  #   :shape - The overall shape of the board.  Valid shapes are:
  #              :square, :rect, :triangle, :rhombus, :hexagon
  #
  #   :width, :height, :length - Define the bounds of the board, the params
  #                              accepted depend on the :shape of the board
  #
  #   :omit - A list of coords to be excluded from the bounds of the board.
  #           Given param should be array.  All the elements will be mapped
  #           to Coord with Coord.[] so symbols and strings are acceptable.
  #
  #   :cell_shape - The shape of the individual cells.  Valid shapes are:
  #                   :square, :hexagon
  #                 The cell_shape will be defaulted depending on the overall
  #                 board shape.  For example, it will be set to :square for
  #                 :square and :rect boards, and :hexagon for :triangle,
  #                 :rhombus, and :hexagon boards.  Not all combinations of
  #                 :shape and :cell_shape are supported, yet.
  #
  #   :directions - In which directions are the cells connected to one another?
  #                 This should be an array containing some subset of:
  #                   [:n, :e, :w, :s, :ne, :nw, :se, :sw]
  #                 If :directions are not given, :cell_shape will be used
  #                 to determine a default.  The directions will effect methods
  #                 like CoordsProxy#neighbors.
  #
  #   :plugins - An array of plugins that the created board should extend.  
  #              Plugins are typically modules under the Board::Plugins 
  #              namespace.  Shorthand can be used to refer to the plugins
  #              in that namespace.  For example, Board::Plugins::Frontier
  #              can be referred to as :frontier.
  #

  def initialize( h )
    @width  = h[:width]
    @height = h[:height]
    @length = h[:length]

    @shape = h[:shape]
    @cell_shape = h[:cell_shape]

    if @cell_shape == :triangle
      if h[:directions]
        raise "Board.new: :directions is invalid when :cell_shape is :triangle"
      end

      @up_directions   = [:w,:e,:s]
      @down_directions = [:n,:e,:w]
    else
      @directions = h[:directions]
    end

    if @shape.nil?
      raise "board requires the :shape param"
    end

    omit = (h[:omit] || []).map { |c| Coord[c] }

    case h[:shape]
      when :square
        @length ||= @width
        @width  ||= @length
        @height ||= @length

        if @length.nil?
          raise "square board requires the :length or :width params"
        end

        @cell_shape ||= :square

        unless @cell_shape == :triangle
          @directions ||= [:n, :s, :e, :w, :ne, :sw, :nw, :se]
        end

      when :rect
        
        if @width.nil? || @height.nil?
          raise "rect board requires both the :width and :height params"
        end

        @cell_shape ||= :square

        unless @cell_shape == :triangle
          @directions ||= [:n, :s, :e, :w, :ne, :sw, :nw, :se]
        end

      when :triangle

        if @length.nil?
          raise "triangle board requires the :length param"
        end

        @width  = @length
        @height = @length

        @width.times do |x|
          @height.times do |y|
            omit << Coord[x,y] if x + y >= length
          end
        end

        @cell_shape ||= :hexagon

        unless @cell_shape == :triangle
          @directions ||= [:n, :s, :e, :w, :ne, :sw]
        end

      when :rhombus

        if @width.nil? || @height.nil?
          raise "rhombus board requires both the :width and :height params"
        end

        @cell_shape ||= :hexagon

        unless @cell_shape == :triangle
          @directions ||= [:n, :s, :e, :w, :ne, :sw]
        end

      when :hexagon

        if @length.nil?
          raise "hexagon board requires the :length param"
        end

        @width  = @length * 2 - 1
        @height = @length * 2 - 1

        @width.times do |x|
          @height.times do |y|
            omit << Coord[x,y] if (x - y).abs >= @length
          end
        end

        @cell_shape ||= :hexagon

        unless @cell_shape == :triangle
          @directions ||= [:n, :s, :e, :w, :nw, :se]
        end
    end

    if @width && @height 
      @cells = Array.new( @width * @height, nil )
      @coords = CoordsProxy.new( self, Coords.new( width, height, omit ) )
    end

    @occupied = Hash.new( [] )
    @occupied[nil] = @coords.to_a.dup

    @plugins = []

    (h[:plugins] || []).each { |p| plugin( p ) }

    init_plugin

    fill( h[:fill] ) if h[:fill]
  end

  # Respond to the values in SHAPES.  See Board.method_missing.

  def Board.respond_to?( m )
    super || SHAPES.include?( m )
  end

  # Turn the values in SHAPES into convenience calls for Board.new.  That is:
  #
  #   Board.new( :shape => :square, :length => 10 )
  #
  # Can be turned into:
  #
  #   Board.square( :length => 10 )
  #

  def Board.method_missing( m, *args )
    if SHAPES.include?( m ) && args.length == 1 && args.first.class == Hash
      args.first[:shape] = m
      new( *args )
    else
      super
    end
  end

  # Perform a deep copy on this board.

  def initialize_copy( original )
    @cells = original.cells.dup
    @occupied = Hash.new( [] )
    original.occupied.each { |k,v| @occupied[k] = v.dup }
  end

  # Initialize plugins.  The init_plugin method should be implemented by
  # any plugins that need to initialize instance variables.  All plugin
  # implementations should be sure to call super (or, else not all plugins
  # will be initialized).

  def init_plugin

  end

  alias_method :__dup, :dup

  # Make a dup of this board.  If it has been extended by any plugins, dup
  # will re-extend the board prior to calling #intialize_copy.  Thus, plugins
  # can implement #initialize_copy as long as they call super.

  def dup
    return __dup if plugins.empty?

    b = Board.allocate

    instance_variables.each do |iv|
      b.instance_variable_set( iv, instance_variable_get( iv ) )
    end

    plugins.each { |p| b.extend( Board.find_plugin( p ) ) }

    b.send( :initialize_copy, self )
    b
  end

  def []( *args )
    if args.length == 2 && args.first.class == Fixnum &&
                           args.last.class  == Fixnum
      return get( args.first, args.last )
    elsif args.length == 1
      return args.first.nil? ? nil : get( args.first.x, args.first.y )
    else
      return args.map do |arg|
        get( arg.x, arg.y )
      end
    end

    nil
  end

  def []=( *args )
    if args.length == 3 && args[0].class == Fixnum &&
                           args[1].class == Fixnum
      return set( args[0], args[1], args[2] )
    elsif args.length == 2
      return args[0].nil? ? nil : set( args[0].x, args[0].y, args[1] )
    else
      args.each { |arg| set( arg.x, arg.y, args.last ) unless arg == args.last }
      return args.last
    end

    nil
  end

  def get( x, y )
    if in_bounds?( x, y )
      return @cells[ci( x, y )]
    end

    nil
  end

  def set( x, y, p )
     if in_bounds?( x, y )
      old = @cells[ci( x, y )]

      before_set( x, y, old )

      @occupied[old].delete( Coord.new( x, y ) )
      
      if @occupied[p].nil? || @occupied[p].empty?
        @occupied[p] = [Coord.new( x, y )]
      else
        @occupied[p] << Coord.new( x, y )
      end

      @cells[ci( x, y )] = p

      after_set( x, y, p )
    end

    p
  end

  def ci( x, y )
    x + y * width
  end

  # Compare boards for equality.

  def ==( o )
    o.respond_to?( :cells ) && o.respond_to?( :width ) &&
    o.width == width && cells == o.cells
  end

  # Return a hash code for this board.

  def hash
    [cells,width].hash
  end

  # Return a count of pieces on the board.  If a piece is given, only that
  # pieces is counted.  If no piece is given, all pieces are counted.  Empty
  # cells are never counted (see #empty_count).

  def count( p=nil )
    return occupied[p].length if p
    occupied.inject(0) { |m,v| m + (v[0] ? v[1].length : 0) }
  end

  # Count of empty (unoccupied) cells.  This is equivalent to calling
  # unoccupied.length.

  def empty_count
    width * height - count
  end

  # Get all the pieces in the selected row.

  def row( y )
    (0...width).map { |x| cells[ci(x,y)] }
  end

  # Move whatever piece is at the start coord (sc) to the end coord (ec).
  # If there was a piece at the end coord it is overwritten.

  def move( sc, ec )
    self[sc], self[ec] = nil, self[sc]
    self
  end

  # Get a list of the coords of unoccupied cells (that is the value at
  # the coord is nil).

  def unoccupied
    occupied[nil]
  end

  # Iterate over each piece on the board.

  def each
    coords.each { |c| yield self[c] }
  end

  # Get the connectivity directions for the given Coord.  Note:  For most
  # boards this is a constant list so you don't have to provide a Coord.  
  # However, if the cells are :triangle shaped, you *must* provide a Coord
  # or an exception will be raised.

  def directions( coord=nil )
    return @directions unless cell_shape == :triangle

    if coord.nil?
      raise "Board#directions requires a Coord when cell_shape is :triangle"
    end

    if coord.y % 2 == 0
      (coord.x % 2 == 0) ? @up_directions : @down_directions
    else
      (coord.x % 2 == 0) ? @down_directions : @up_directions
    end
  end

  # Iterate over pieces from the start coord in the given directions.  The
  # start coord is not included.

  def each_from( s, directions )
    i = 0
    directions.each do |d|
      c = s
      while (c = coords.next( c, d )) && yield( self[c] )
        i += 1
      end
    end
    i
  end

  # Clear all the pieces from the board.

  def clear
    fill( nil )
  end

  # Fill the entire board with the given piece.

  def fill( p )
    if coords.omitted.empty?
      cells.each_index { |i| cells[i] = p }

      @occupied = Hash.new( [] )
      @occupied[p] = @coords.to_a.dup
    else
      coords.each { |c| self[c] = p }
    end

    self
  end

  def in_bounds?( x, y )
    if x < 0 || x >= width || y < 0 || y >= height
      return nil
    end

    true
  end

  # This can be overridden perform some action before a cell on the board is
  # overwritten (as with #[]=).  The given piece (p) is the value at the given
  # (x,y) coordinate before it's changed.

  def before_set( x, y, p )
  end

  # This can be overridden perform some action after a cell on the board has
  # been overwritten (as with #[]=).  The given piece (p) is the value at the 
  # given (x,y) coordinate after it's been changed.

  def after_set( x, y, p )
  end

  # Returns a string representation of this Board.  This is simple 
  # fixed-width ascii with one character per cell.  The character is the
  # first letter of the string representation of the piece in that cell.
  # The rows and columns are all labeled.

  def to_s
    off = height >= 10 ? 2 : 1                                
    w = width

    letters = ' '*off + 'abcdefghijklmnopqrstuvwxyz'[0..(w-1)] + ' '*off + "\n"

    s = letters
    height.times do |y|
      s += sprintf( "%*d", off, y+1 )
      s += row(y).inject( '' ) do |rs,p|
        rs + (p.nil? ? ' ' : p.to_s[0..0])
      end
      s += sprintf( "%*d\n", -off, y+1 )
    end
    s + letters
  end

  class CoordsProxy
    def initialize( board, coords )
      @board, @coords = board, coords
    end

    def ring( coord, d )
      @coords.ring( coord, d, @board.cell_shape, @board.directions( coord ) )
    end

    def neighbors( coord )
      @coords.neighbors( coord, @board.directions( coord ) )
    end

    def neighbors_nil( coord )
      @coords.neighbors_nil( coord, @board.directions( coord ) )
    end

    def to_a
      @coords.to_a
    end

    def respond_to?( m )
      m != :_dump && (super || @coords.respond_to?( m ))
    end

    def method_missing( m, *args, &block )
      if m != :_dump && @coords.respond_to?( m ) 
        @coords.send( m, *args, &block )
      else
        super
      end
    end

    # No need to save the board itself.  Board#yaml_initialize will reset
    # itself.

    def to_yaml_properties
      ["@coords"]
    end
  end

  # Namespace for plugins.

  module Plugins
  end

  # Find Board plugins (Modules).  Given a string like 
  # "Board::Plugins::Frontier" it will return that module.  Given a string
  # like "frontier" or the symbol :frontier, it will look in the Board::Plugins
  # namespace for a module named Frontier.  If the string where to contain
  # underscores it would be translated from snake case to camel case.

  def self.find_plugin( s )
    return s  if s.nil? || s.kind_of?( Module )

    # Assume strings that look like constants are defined rooted under Object.

    if s.to_s =~ /^[A-Z]/

      if Object.nested_const_defined?( s.to_s )
        Object.nested_const_get( s.to_s )
      end

    else  # Otherwise, assume we're looking under Board::Plugins

      m = s.to_s.gsub( /_(.)/ ) { $1.upcase }.gsub( /^(.)/ ) { $1.upcase }

      if Board::Plugins.nested_const_defined?( m )
        Board::Plugins.nested_const_get( m )
      end
    end
  end

  # When loading a YAML-ized Board, be sure to re-extend plugins.

  def yaml_initialize( t, vals )
    vals.each do |iv,v|
      instance_variable_set( "@#{iv}", v )
      v.each { |p| extend Board.find_plugin( p ) } if iv == "plugins"
      v.instance_variable_set( "@board", self ) if iv == "coords"
    end
  end

  private

  # Extend self with the given plugin and any dependencies (that haven't
  # already been loaded).

  def plugin( p )
    if p = self.class.find_plugin( p )
      ps = p.to_s

      return if @plugins.include?( ps )

      @plugins << ps
      extend p

      if p.respond_to?( :dependencies )
        p.dependencies.each do |dp|
          plugin( dp )
        end
      end

    end
  end

end

