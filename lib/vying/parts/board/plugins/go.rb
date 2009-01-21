require 'vying'

module Board::Plugins::Go

  def init_plugin
    @directions = [:n, :s, :e, :w]
  end

  def put_stone(c, p)
    self[c] = p
    prisoners = []
    c = c.to_coords.first
    coords.neighbors(c).each { |nc|
      next if self[nc].nil? || self[nc] == p

      if count_liberties(nc) == 0
        prisoners.concat(capture_group(nc))
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

    captured = []
    while(c = todo.pop)
      captured.push(c)
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
    return captured
  end

  # List groups belonging to player p. If p
  # is nil, list all groups
  def list_groups(p=nil)
    if p.nil?
      return list_groups(:black) + list_groups(:white)
    else
      c = 'a1'.to_coords.first
      todo = [c]
      groups = []
      all = { c => nil }
      seen = { c => true }

      ((coords.bounds.first.x)..(bounds.last.x)).each do |x|
        ((coords.bounds.first.y)..(bounds.last.y)).each do |y|
          c = Coord.new(x, y)
          seen[c] = true
          if self[c] != nil
            if self[c] == p
              n = coords.neighbors(c, [:n, :w])
              gn = all[n[0]]
              gw = all[n[1]]
              if gn && gw && gn != gw
                # we merge both groups in gn
                groups.delete(gw)
                gn = gn.concat(gw)
                all.find_all { |k,v| v == gw }.each { |k,v| all[k] = gn }
                # and add c to gn
                gn << c
                all[c] = gn
              elsif gn
                gn << c
                all[c] = gn
              elsif gw
                gw << c
                all[c] = gw
              else
                all[c] = [c]
                groups << all[c]
              end
            end
          end
        end
      end

      return groups
    end
  end
end
