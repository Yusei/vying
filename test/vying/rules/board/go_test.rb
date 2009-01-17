require 'test/unit'

require 'vying'
require 'vying/rules/rules_test'

class TestGo < Test::Unit::TestCase
  include RulesTests

  def rules
    Go
  end

  def test_info
    assert_equal('Go', rules.name)
  end

  def test_players
    assert_equal([:black,:white], rules.new.players)
  end

  def test_has_moves
    g = Game.new( rules )
    assert_equal( [:black], g.has_moves )
    g << g.moves.first
    assert_equal( [:white], g.has_moves )
  end

  def test_liberty_count
    g = Game.new( rules )
    g << %w{a1 s9 g7 s10 h7 s11 h8 s12 i9 i7}
    assert(g.board.count_liberties('a1') == 2)
    assert(g.board.count_liberties('s12') == 6)
    assert(g.board.count_liberties('g7') == 6)
  end

  def test_capture
    # capture in the corner
    g = Game.new( rules )
    g << %w{a1 b1 a5 a2}
    assert(g.board[:a1] == nil)

    # capture in the center
    g = Game.new( rules )
    g << %w{q3 p2 p3 q2 q4 r3 p5 q5 o4 r4 o5 p6
            o6 o7 a5 n6 a7 n5 a8 n4 a9 o3 a10}
    # now white p4 should capture two black groups
    # of 4 and 3 stones
    assert(g.prisoners[:white] == 0)
    assert(g.prisoners[:black] == 0)
    g << 'p4'
    assert(g.prisoners[:white] == 7)
    assert(g.prisoners[:black] == 0)
    %w{q3 p3 q4 p5 o4 o5 o6}.each { |c|
      assert(g.board[c] == nil)
    }
  end

  def test_suicide_rule
    g = Game.new( rules )
    g << %w{f5 p3 g4 p4 h5 p5 g6 q6 q5 r5 q4 q2
            l3 r3 l4 r4}
    # now white g5 and black q3 should be
    # forbidden
    assert( !g.moves.include?('q3') )
    g << 'a1'
    assert( !g.moves.include?('g5') )
  end

  def test_ko
    g = Game.new( rules )
    g << %w{j8 j11 i9 i10 k9 k10 j10 j9}
    # black j10 should be forbidden by the ko rule
    assert( !g.moves.include?('j10') )
    # so we move elsewhere
    g << 'a1'
    # so does white
    g << 'a2'
    # black j10 is no longer forbidden
    assert( g.moves.include?('j10') )
  end

  def test_superko
    assert(false)
  end
end
