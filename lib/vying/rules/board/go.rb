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
      @scoreboard = nil
      @prisoners = {:black => 0, :white => 0}
      @ko_move = nil
      @pass_count = 0
      @counting = false
      @final = false
    end

    def moves
      if final?
        []
      elsif counting?
        board.occupied << 'done'
      else   
        m = board.non_suicide_moves(turn)
        if @ko_move
          m.delete(@ko_move)
        end
        m << 'pass'
        return m
      end
    end

    def has_moves
      if counting?
        [:black, :white]
      else
        [turn]
      end
    end

    def begin_counting_phase
      @scoreboard = @board.dup
      @counting = true
    end

    def apply!(move)
      unless counting?
        if move.to_s == 'pass'
          @pass_count += 1
          if @pass_count == 2
            @pass_count = 0
            begin_counting_phase
          else
            rotate_turn
          end
          return self
        end

        @pass_count = 0
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
      else
        # counting phase
        if move.to_s == 'done'
          @pass_count += 1
          if @pass_count == 2
            @pass_count = 0
            # add the score here
            @final = true
          else
            rotate_turn
          end
          return self
        end
      end
      self
    end

    def counting?
      @counting
    end

    def final?
      @final
    end

    def winner?(player)
      false
    end

    def loser?(player)
      winner?(opponent(player))
    end

    def score?( player )
      if final?
      else
        0
      end
    end
  end
end
