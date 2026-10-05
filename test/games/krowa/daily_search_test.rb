require_relative '../../support/ui'
require_relative '../../support/krowa_services'
require_relative '../../../games/krowa_support/leaderboards'

bank = GameRoomGames::KrowaWordBank.default
tables = KrowaTestTables.new
store = GameRoomGames::KrowaServerStore.new(server_tables: tables, bank: bank, user: 'Alice')
assignments = tables.fetch('krowa_daily_assignments')
scores = tables.fetch('krowa_daily_scores')
%w[2026-09-27 2026-09-28 2026-09-29].each do |date|
  assignments.insert('day_key' => date.delete('-').to_i, 'assignment' => GameRoomKrowa::DailyAssignment.seal(date, 'arfa'))
  scores.insert('day_key' => date.delete('-').to_i, 'attempts' => 7)
end
assignments.insert('day_key' => 20260927, 'assignment' => GameRoomKrowa::DailyAssignment.seal('2026-09-27', 'bele'))
scores.insert('day_key' => 20260927, 'attempts' => 4)
scores.insert('day_key' => 20260926, 'attempts' => 2) # No reliable assignment.
assignments.insert('day_key' => 20260925, 'assignment' => 'broken')
scores.insert('day_key' => 20260925, 'attempts' => 3)
assert(store.publish_word('arfa', 5) == :published, 'ordinary setup failed')
rows = store.search_ranked_words('ARF', today: '2026-09-28')
assert(rows.length == 2, 'ordinary word or past day missing; current/future day leaked')
assert(rows.all? { |row| row['word'] == 'arfa' }, 'canonical assignment changed')
daily = rows.find { |row| row['daily_date'] }
assert(daily['daily_date'] == '2026-09-27' && daily['best_attempts'] == 4, 'wrong daily route/result')
assert(store.search_ranked_words('bele', today: '2026-09-28').empty?, 'noncanonical duplicate assignment used')
assert(store.search_ranked_words('arfa', today: nil).empty?, 'search revealed words without a confirmed date')
assert(store.search_ranked_words('', today: '2026-09-28').empty?, 'empty search read everything')
assert(scores.queries.none? { |query| query[:where].key?('day_key') }, 'search performs one request per day')

client = GameRoomGames::KrowaLeaderboardClient.new(nil, nil, store: store)
def client.show_table(_columns, rows, **_options); @seen_rows = rows; @selected; end
def client.show_daily_ranking(date); @opened = [:daily, date]; end
def client.show_word_ranking(word); @opened = [:word, word]; end
rows.each_with_index do |row, index|
  client.instance_variable_set(:@selected, index)
  client.send(:show_word_browser, rows, header: 'search')
  expected = row['daily_date'] ? [:daily, row['daily_date']] : [:word, row['word']]
  assert(client.instance_variable_get(:@opened) == expected, 'search opened the wrong leaderboard')
end
puts 'PASS Krowa search: canonical past days, ordinary words, private today, no guessed history and correct UI routing'
