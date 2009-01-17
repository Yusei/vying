require 'vying'

Rules.create("Go") do
  name    "Go"
  version "0.1.0"

  players :black, :white

  cache :moves

  position do
    attr_reader :board, :prisoners, :ko_move

    def init
      @board = Board.square(19, :plugins => [:go])
      @prisoners = {:black => 0, :white => 0}
      @ko_move = nil
    end

    def moves
      if final?
        []
      elsif counting?
        
      else   
        m = board.non_suicide_moves(turn)
        if @ko_move
          m.delete(@ko_move)
        end
        return m
      end
    end

    def apply!(move)
      captured = board.put_stone(move, turn)
      prisoners[turn] += captured.size

      # check for possible ko if exactly one
      # stone was captured
      @ko_move = nil
      if captured.size == 1
        if board.count_liberties(move) == 1
          @ko_move = captured.first
        end
      end

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
