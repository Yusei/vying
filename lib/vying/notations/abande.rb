class AbandeNotation < Notation
 
  def self.notation_name
    :abande_notation
  end
 
  def initialize( game )
    super( game )
    @board_size = game.options[:board_size]
  end

  def to_move( s, player )
    if s =~ /^\s*(\w\d)\s*$/
      conv( $1 )
    elsif s =~ /^\s*(\w\d)-?(\w\d)\s*$/
      conv( $1 ) + conv( $2 )
    else
      raise "#{s} is an invalid notation format"
    end
  end
 
  def translate( move, player )
    s = ''
    move.to_coords.each do |c|
      if c.x >= @board_size
        s += (97 + c.x).chr + (c.y - (c.x - @board_size)).to_s
      else
        s += c.to_s
      end
    end
    s =~ /(\w\d)(\w\d)/ ? "#{$1}-#{$2}" : s
  end

  private

  def conv( c )
    if c.x >= @board_size
      (97 + c.x).chr + (c.y + (c.x - @board_size) + 2).to_s
    else
      c
    end
  end

end
