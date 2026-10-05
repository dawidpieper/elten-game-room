require_relative '../support/localization'
runtime = GameRoomTestLocalization.use_language('pl')
Programs.with_runtime(runtime) { require_relative '../support/table_watch_runtime' }

game = EltenGameRoom::GAME_REGISTRY.build('cat_head_tail')
[[], ['cs']].each do |known|
  runtime.settings['known_languages'] = known
  GameRoomLocalization.boot(runtime: runtime, host_language: 'pl')
  label = game.option_definitions.find { |option| option.key == 'score_limit' }.label
  raise "Czech fallback replaced Polish: #{label}" unless label == 'Limit punktów'
  raise 'Author translation changed' unless game.send(:_, 'Roll') == 'Rzuć kością'
  raise 'Title was translated' unless game.name == 'Cat, head, tail'
end

GameRoomLocalization.available_languages.each do |language|
  GameRoomLocalization.boot(settings: {'interface_language' => language[:id], 'known_languages' => []})
  raise "Translated title in #{language[:id]}" unless game.name == 'Cat, head, tail'
end
GameRoomLocalization.boot(settings: {'interface_language' => 'cs', 'known_languages' => ['pl']})
raise 'Czech primary lost its own text' unless game.option_definitions.first.label == 'Bodový limit'

module Session
  def self.languages; raise 'Language defaults read account languages'; end
end
GameRoomLocalization.boot(settings: {}, host_language: 'pl')
raise 'Account/default language was checked' unless GameRoomLocalization.normalize_settings({}) ==
  {'interface_language' => 'pl', 'known_languages' => []}
puts 'PASS actual Cat, head, tail catalogs: primary/common priority, author context, all title languages and empty defaults'
