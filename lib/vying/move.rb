# Copyright 2007-08, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying'

# Move is used solely by history.  It should be compatible with Game / Position
# but as a rule, you want to use Strings to represent moves.  However, be aware
# that the values in History#moves will be Move objects.
#
# Move#to_s will give you the String representation of the move.
# Move#by will give you the player name symbol (not a Player object)
# Move#at will give you the Time the move was made (if it's known)
#

class Move

  attr_reader :by, :at

  # Initialize a Move with the String representation, the player who made the
  # move, and the time the move was made.

  def initialize( s, by=nil, at=Time.now )
    @move, @by, @at = s.to_s, by, at

    @by ||= special_by
  end

  # Moves are considered to be equal if they share the same #to_s and #by.

  def eql?( o )
    o.kind_of?( Move ) &&
    to_s == o.to_s &&
    by == o.by
  end

  # See #eql?

  def ==( o )
    eql?( o )
  end

  # Hash based on the move string and player symbol.

  def hash
    [@move, @by].hash
  end

  # Equivalent to Move#to_s === o

  def ===( o )
    @move === o
  end

  # Equivalent to Move#to_s =~ o

  def =~( o )
    @move =~ o
  end

  # Returns the string representation of the move.  This can be passed to
  # Game / Position methods that expect a move.  Note, this isn't strictly
  # necessary as those methods typically call #to_s on whatever object they
  # are given.

  def to_s
    @move
  end

  # More detailed inspect string.

  def inspect
    "#<Move #{@move} by: #{by} at: #{at}>"
  end

  # These special moves are stored in History (they mix a module into 
  # the preceding position, changing its behavior.

  HISTORY_SPECIAL_MOVES = { 
    /^draw_offered_by_(\w+)/     => DrawOffered,
    /^draw_accepted_by_(\w+)/    => DrawAccepted,
    /^undo_requested_by_(\w+)/   => UndoRequested,
    /^undo_accepted_by_(\w+)/    => UndoAccepted,
    /(\w+)_resigns$/             => Resign,
    /^time_exceeded_by_(\w+)/    => TimeExceeded,
    /^draw$/                     => NegotiatedDraw,
    /^swap$/                     => Swapped
  }

  # These special moves are not stored in History.  They are translated
  # to method calls on Game that occur immediately before the move is added
  # to history (if it even is).

  CALL_BEFORE = {
    /^reject_draw$/              => :reject_draw,
    /^reject_undo$/              => :reject_undo,
    /^undo$/                     => :undo,
    /^swap$/                     => :swap,
    /(\w+)_withdraws$/           => :withdraw,
    /^kick_(\w+)$/               => :kick 
  }

  # These special moves are not stored in History.  They are translated
  # to method calls on Game that occur immediately after the move is
  # added to history (if it even is).

  CALL_AFTER = {
    /^draw_accepted_by_\w+/      => :accept_draw,
    /^undo_accepted_by_\w+/      => :accept_undo
  }

  # Is this a special move?

  def special?
    HISTORY_SPECIAL_MOVES.any? { |p,m| @move =~ p } ||
    CALL_BEFORE.any? { |p,m| @move =~ p } ||
    CALL_AFTER.any? { |p,m| @move =~ p }
  end

  # If this is a special_move does it add a position to the history?

  def add_to_history?
    HISTORY_SPECIAL_MOVES.any? { |p,m| @move =~ p }
  end

  # If this is a special move, should we call a method on Game prior to
  # (maybe) adding it to history?

  def call_before?
    CALL_BEFORE.any? { |p,m| @move =~ p }
  end

  # If this is a special move, should we call a method on Game after
  # (maybe) adding it to history?

  def call_after?
    CALL_AFTER.any? { |p,m| @move =~ p }
  end

  # If this move is stored in History, get the module to mixin.

  def special_module
    p, m = HISTORY_SPECIAL_MOVES.find { |p,m| @move =~ p }
    m
  end

  # If this move results in a method call on Game, get the method and args

  def before_call
    CALL_BEFORE.each do |p,s| 
      if @move =~ p 
        return [s, $~.captures]
      end
    end
    nil
  end

  # If this move results in a method call on Game, get the method and args

  def after_call
    CALL_AFTER.each do |p,s| 
      if @move =~ p 
        return [s, $~.captures]
      end
    end
    nil
  end

  # Who is this special move by?  This is used to extract a player name
  # for Position#apply_special.

  def special_by
    player = nil
    HISTORY_SPECIAL_MOVES.each { |p,m| player = $1.intern if @move =~ p && $1 }
    player
  end

  # Apply this move to the given position.  If necessary a module will be
  # mixed into a dup of the position (and Position#apply_special will be
  # called.  For example, of such a module see TimeExceeded.  If no module
  # is mixed in (a normal move) then Position#apply is called.  The resulting
  # position is returned.

  def apply_to( position )
    if mod = special_module
      p = position.dup
      p.extend mod
      p.apply_special( to_s, by )
      p

    else
      position.apply( to_s, by )
    end
  end

  # Forwards #x to String#x

  def x
    @move.x
  end

  # Forwards #y to String#y

  def y
    @move.y
  end

  # Forwards #to_coords to String#to_coords

  def to_coords
    @move.to_coords
  end

end
