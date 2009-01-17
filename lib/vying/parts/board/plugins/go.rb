require 'vying'

module Board::Plugins::Go

  def init_plugin
    @directions = [:n, :s, :e, :w]
  end

  def put_stone(c, p)
    self[c] = p
    prisoners = 0
    c = c.to_coords.first
    coords.neighbors(c).each { |nc|
      next if self[nc].nil? || self[nc] == p

      if count_liberties(nc) == 0
        prisoners += capture_group(nc)
      end
    }
    return prisoners
  end

  def non_suicide_moves(turn)
    c = nil
    unoccupied.find_all { |b|
      c = b.to_coords.first
      r = false
      coords.neighbors(c).each { |nc|
        if self[nc].nil?
          # we've got at least one liberty
          r = true
        elsif self[nc] != turn
          # we can capture this group
          # if its only liberty is where we're
          # moving
          r ||= count_liberties(nc) == 1
        else
          # we're connecting to one of our groups
          # with more than one liberty
          r ||= count_liberties(nc) > 1
        end
      }
      r
    }
  end

  # Count the number of liberties of the
  # group of stones linked to c.
  def count_liberties(c)
    c = c.to_coords.first
    p = self[c]

    f = 0
    todo = [c]
    all = { c => c }

    while(c = todo.pop)
      coords.neighbors(c).each { |nc|
        unless all[nc]
          all[nc] = nc
          case self[nc]
          when nil
            f += 1
          when p
            todo.push(nc)
          end
        end
      }
    end

    return f
  end

  def capture_group(c)
    p = self[c]

    todo = [c]
    all = { c => c }

    count = 0
    while(c = todo.pop)
      count += 1
      self[c] = nil
      coords.neighbors(c).each { |nc|
        unless all[nc]
          all[nc] = nc
          if self[nc] == p
            todo.push(nc)
          end
        end
      }
    end
    return count
  end

end
