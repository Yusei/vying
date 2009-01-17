require 'vying'

Rules.create("Go") do
  name    "Go"
  version "0.1.0"

  players :black, :white

  cache :moves

  position do
    attr_reader :board, :prisoners

    def init
      @board = Board.square(19, :plugins => [:go])
      @prisoners = {:black => 0, :white => 0}
    end

    def moves
      if final?
        []
      elsif counting?
        
      else   
        board.non_suicide_moves(turn)
      end
    end

    def apply!(move)
      @prisoners[turn] += board.put_stone(move, turn)
      rotate_turn
      self
    end

    def counting?
      false
    end

    def final?
      false
    end

    def winner?(player)
      false
    end

    def loser?(player)
      winner?(opponent(player))
    end
  end
end
