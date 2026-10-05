require 'tmpdir'
require_relative '../support/background_help_game_screen'
require_relative '../../lib/table_history_exporter'

# Exercise the production GameScreen loop and native menu callback, not a
# direct call to the exporter. The network and host UI peripherals are local.
h, screen = screen_fixture(GameRoomGames::FourInARow.new)
activity = TableActivityRepository.new(transport: h.transports.fetch('Alice'), server_tables: {})
screen.instance_variable_set(:@activity_repository, activity)
h.as('Alice') { activity.append(table: h.table, kind: 'chat', message: 'Cześć, moja wiadomość') }
h.write('Alice', [GameRoomGames::EventCommand.new(action: 'drop', value: '1')])
h.as('Bob') do
  TableActivityRepository.new(transport: h.transports.fetch('Bob'), server_tables: {})
    .append(table: h.table, kind: 'chat', message: 'Odpowiedź gracza')
end
h.write('Bob', [GameRoomGames::EventCommand.new(action: 'drop', value: '7')])

exports = []
locations = [[:game, 0], [:chat, 0], [:history, 0], [:users, 0]]
stage = :export
exported_location = nil
expected_history = nil
Dir.mktmpdir do |directory|
  screen.instance_variable_set(:@save_table_history, lambda do |entries|
    assert(entries.map(&:text) == expected_history, 'Export differs from the displayed complete history')
    exports << GameRoomTableHistoryExporter.new.write(directory, entries)
    # Both return values must leave the table open. The separate dialog test
    # covers cancellation before writing and a failed file operation.
    exports.length.odd?
  end)
  Form.driver = lambda do |form|
    layout = screen.instance_variable_get(:@layout)
    case stage
    when :export
      layout.chat.set_text('Niewysłany szkic')
      layout.chat.index = 4
      layout.chat.check = 9
      exported_location = locations.shift
      field = case exported_location.first
      when :game then layout.surface.fields.first
      when :chat then layout.chat
      when :history then layout.history
      when :users then layout.users
      end
      form.index = form.fields.index(field)
      expected_history = layout.history.items.dup
      menu = FakeMenu.new
      form.context(menu, true)
      item = menu.options.find { |option| option[2] == 'S' }
      assert(item && item[0] == 'Save table history', 'Ctrl+Shift+S is missing from the active table menu')
      stage = :returned
      item[3].call
    when :returned
      assert(layout.focus_location == exported_location, 'Export moved focus to another section')
      assert(layout.chat.text == 'Niewysłany szkic' && layout.chat.index == 4 && layout.chat.check == 9,
        'Export lost the unsent chat draft or selection')
      assert(h.events('Alice').length == 2, 'Export submitted a move, restarted or closed the game')
      text = File.binread(exports.last).force_encoding(Encoding::UTF_8)
      assert(text.valid_encoding? && text.include?('Cześć, moja wiadomość') && text.include?('Odpowiedź gracza'),
        'Export lost either side of the chat or Polish characters')
      if locations.empty?
        h.write('Alice', [GameRoomGames::EventCommand.new(action: 'drop', value: '2')])
        stage = :after_move
      else
        stage = :export
      end
    when :after_move
      # Wait until the normal presenter has received the subsequent move.
      if screen.send(:event_presenter).instance_variable_get(:@last_seen_event_id).to_i >= h.events('Alice').last['__id'].to_i
        layout.back_button.trigger(:press)
        stage = :done
      end
    end
  end
  h.as('Alice') { assert(screen.run == :back, 'History export changed normal table exit') }
  assert(stage == :done && exports.length == 4 && exports.uniq.length == 4, 'Not every focus location was checked')
end
Form.driver = nil
h.assert_converged('history export and next move', expected_count: 3)
puts 'PASS table-history menu: all four sections, full chat and game history, callback returns, preserved draft/focus and subsequent move'
