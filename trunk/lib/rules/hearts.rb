require 'game'
require 'cards/standard'

class Hearts < TrickTakingRules

  info :name => 'Hearts'

  players [:n, :e, :s, :w]

  deck [:SA,:SK,:SQ,:SJ,:ST,:S9,:S8,:S7,:S6,:S5,:S4,:S3,:S2,
        :CA,:CK,:CQ,:CJ,:CT,:C9,:C8,:C7,:C6,:C5,:C4,:C3,:C2,
        :HA,:HK,:HQ,:HJ,:HT,:H9,:H8,:H7,:H6,:H5,:H4,:H3,:H2,
        :DA,:DK,:DQ,:DJ,:DT,:D9,:D8,:D7,:D6,:D5,:D4,:D3,:D2]

  suits :spades   => [:SA,:SK,:SQ,:SJ,:ST,:S9,:S8,:S7,:S6,:S5,:S4,:S3,:S2],
        :clubs    => [:CA,:CK,:CQ,:CJ,:CT,:C9,:C8,:C7,:C6,:C5,:C4,:C3,:C2],
        :hearts   => [:HA,:HK,:HQ,:HJ,:HT,:H9,:H8,:H7,:H6,:H5,:H4,:H3,:H2],
        :diamonds => [:DA,:DK,:DQ,:DJ,:DT,:D9,:D8,:D7,:D6,:D5,:D4,:D3,:D2]

  trump             []
  lead              [Card[:C2], :any]
  follow            [:must_follow_suit]
  deal_out          13
  wait_until_broken [:HA,:HK,:HQ,:HJ,:HT,:H9,:H8,:H7,:H6,:H5,:H4,:H3,:H2]

  attr_reader :hands, :tricks, :trick, :broken, :score

  random

  def initialize( seed=nil )
    super

    @hands = {}
    d = Deck.new( deck, rng ).shuffle.deal( players.size, deal_out )
    d.zip( players ) { |h,p| @hands[p] = h }

    turn( :rotate ) until hands[turn].include?( Card[:C2] )

    @tricks = {}
    @trick = []
    @broken = false
    @score = Hash.new( 0 )
  end

  def censor( player )
    pos = super
    pos.hands.each { |k,v| pos.hands[k] = :hidden if k != player }
    pos
  end

  def score_hand
    tmp_scores = Hash.new( 0 )

    # or here
    tricks.each do |p,ts|
      cards = ts.map { |t| t.map { |p2,c| c } }.flatten!
      tmp_scores[p] += cards.inject( 0 ) do |s,c| 
        v = 0
        v = 1  if c.suit == :hearts
        v = 13 if c == Card[:SQ]
        s + v
      end
    end

    # something wrong here
    if (shot_moon = tmp_scores.select { |k,v| v == 26 }).size != 0
      tmp_scores.each { |k,v| score[k] += 26 if k != shot_moon[0] }
    else
      tmp_scores.each { |k,v| score[k] += v }
    end
  end

  def final?
    score.select { |k,v| v >= 100 }.size > 0
  end

  def winner?( player )
    lowest = [:nobody,200]
    score.each { |k,v| lowest = [k,v] if v < lowest[1] }
    player == lowest[0]
  end

  def loser?( player )
    lowest = [:nobody,200]
    score.each { |k,v| lowest = [k,v] if v < lowest[1] }
    player != lowest[0]
  end
end

