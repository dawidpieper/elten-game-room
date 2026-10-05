require 'tmpdir'
require_relative '../support/binary_rules_load'
require EltenTestHost.file('src/bootstrap.rb')

module Dirs
  class << self
    attr_accessor :documents
  end
end

GameRoomTestLocalization.use_language('pl')
app = EltenGameRoom.allocate
selected = nil
messages = []
dialogs = []
app.define_singleton_method(:get_file) do |title, **options|
  dialogs << [title, options]
  selected
end
app.define_singleton_method(:alert) { |text| messages << text }
app.define_singleton_method(:run_network_task) { |*| raise 'Local history export contacted the server' }
entries = [GameRoomHistory::Entry.new(text: 'Łukasz: Cześć!'.b, category: :chat)]

Dir.mktmpdir('historia-żółć-') do |directory|
  Dirs.documents = directory
  raise 'Cancelling claimed success' unless app.send(:save_table_history, entries) == false
  raise 'Cancelling wrote a file or announced success' unless Dir.children(directory).empty? && messages.empty?
  raise 'Wrong native folder picker options' unless dialogs.last == ['Zapisz historię stołu',
    {path: EltenPath.with_separator(directory), save: true}]

  selected = directory.tr('/', '\\')
  raise 'Saving did not succeed' unless app.send(:save_table_history, entries)
  files = Dir.glob('*.txt', base: directory)
  raise 'History was not written to the selected folder' unless files.length == 1
  path = File.join(directory, files.first)
  raise 'Binary Polish chat was damaged' unless File.binread(path).force_encoding('UTF-8') == "Łukasz: Cześć!\r\n"
  raise 'Wrong localized success message' unless messages.last == "Historia stołu została zapisana w #{path}."

  selected = File.join(directory, 'does-not-exist')
  raise 'A failed write claimed success' unless app.send(:save_table_history, entries) == false
  raise 'Write error escaped without a localized message' unless messages.last == 'Nie udało się zapisać historii stołu.'
  raise 'Failure damaged the previous export' unless Dir.glob('*.txt', base: directory) == files
end

puts 'PASS binary application export: native path API, Polish folder/message/text, cancel without write, successful save, write error and no network'
