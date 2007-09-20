require 'vying/ai/bot'
require 'vying/ai/search'

class RandomBot < AI::Bot
  def select( sequence, position, player )
    ops = position.ops
    ops[rand(ops.size)]
  end
end

