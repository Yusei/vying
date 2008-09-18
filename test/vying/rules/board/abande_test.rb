require 'test/unit'

require 'vying'
require 'vying/rules/rules_test'

class TestAbande < Test::Unit::TestCase
  include RulesTests

  def rules
    Abande
  end

  def test_info
    assert_equal( "Abande", rules.name )
    assert( rules.version == '0.1.0' )
    assert( rules.score_determines_outcome )
  end

  def test_players
    assert_equal( [:black, :white], rules.new.players )
  end

  def test_initialize
    g = Game.new( rules )

    assert_equal( 37, g.board.unoccupied.length )
    assert_equal( 18, g.pool[:white] )
    assert_equal( 18, g.pool[:black] )
    assert_equal( :black, g.turn )
  end

#  def test_options
#    assert_equal( 4, rules.options[:board_size].default )
#    assert_equal( [3, 4, 5, 6], rules.options[:board_size].values )
#
#    assert_equal( 4, rules.new.board.length )
#    assert_equal( 3, rules.new( :board_size => 3 ).board.length )
#    assert_equal( 4, rules.new( :board_size => 4 ).board.length )
#    assert_equal( 5, rules.new( :board_size => 5 ).board.length )
#    assert_equal( 6, rules.new( :board_size => 6 ).board.length )
#
#    assert_raise( RuntimeError ) { rules.new( :board_size => 2 ) }
#    assert_raise( RuntimeError ) { rules.new( :board_size => 7 ) }
#  end

  def test_has_moves
    g = Game.new( rules )
    assert_equal( [:black], g.has_moves )
    g << g.moves.first
    assert_equal( [:white], g.has_moves )
  end

  def test_play
    g = Game.new( rules )

    assert_equal( 37, g.moves.length )

    g << "d4"
    assert_equal( [:black], g.board[:d4] )
    assert_equal( 18, g.pool[:white] )
    assert_equal( 17, g.pool[:black] )

    assert_raise( RuntimeError ) { g << "d4" }
    assert_raise( RuntimeError ) { g << "a1" }

    g << "c3"
    assert_equal( [:white], g.board[:c3] )
    assert_equal( 17, g.pool[:white] )
    assert_equal( 17, g.pool[:black] )
  end

end

