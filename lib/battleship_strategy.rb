require_relative "game_bots"

module BattleshipPlanning
  class Strategy
    def initialize(fallback: GameRoomBots::HeuristicStrategy.new)
      @fallback = fallback
    end

    def choose(actions:, actor:, random_source:, game:, replay:, context: nil, **_extra)
      choices = actions.to_a
      return nil if choices.empty?
      return choices.first if choices.length == 1

      @fallback.choose(
        actions: choices, actor: actor, random_source: random_source,
        game: game, replay: replay, context: context
      )
    end

    def cell_value(game, state, player, cell)
      size = game.board_size
      shots = state[:shots].fetch(player, {})
      return -1_000.0 if shots.key?(cell)

      wounded = wounded_hits(shots, size)
      return chase_value(shots, wounded, cell, size) if !wounded.empty?

      search_value(game, state, shots, cell, size)
    end

    private

    def wounded_hits(shots, size)
      struck = shots.select { |_cell, result| result != "miss" }.keys
      finished = sunk_cells(shots, struck, size)
      struck.reject { |cell| finished.include?(cell) }
            .select { |cell| neighbours(cell, size).any? { |near| !shots.key?(near) } }
    end

    def sunk_cells(shots, struck, size)
      done = []
      struck.each do |cell|
        next if shots[cell] != "sunk" || done.include?(cell)

        queue = [cell]
        while (current = queue.shift)
          next if done.include?(current)

          done << current
          queue.concat(neighbours(current, size).select { |near| struck.include?(near) })
        end
      end
      done
    end

    def chase_value(shots, wounded, cell, size)
      touching = wounded.select { |hit| neighbours(hit, size).include?(cell) }
      return -50.0 if touching.empty?

      touching.sum { |hit| 40.0 + axis_bonus(wounded, hit, cell, size) }
    end

    def axis_bonus(wounded, hit, cell, size)
      same_row = hit / size == cell / size
      aligned = wounded.any? do |other|
        next false if other == hit

        same_row ? other / size == hit / size : other % size == hit % size
      end
      aligned ? 30.0 : 0.0
    end

    def search_value(game, state, shots, cell, size)
      step = game.fleet_of(state).min
      parity = step <= 1 ? 0 : ((cell % size) + (cell / size)) % step
      (parity.zero? ? 20.0 : 0.0) + open_neighbours(shots, cell, size) * 2.0
    end

    def open_neighbours(shots, cell, size)
      neighbours(cell, size).count { |near| !shots.key?(near) }
    end

    def neighbours(cell, size)
      x = cell % size
      y = cell / size
      [[1, 0], [-1, 0], [0, 1], [0, -1]].filter_map do |dx, dy|
        nx = x + dx
        ny = y + dy
        ny * size + nx if nx.between?(0, size - 1) && ny.between?(0, size - 1)
      end
    end
  end
end
