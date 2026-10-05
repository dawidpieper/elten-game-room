# encoding: UTF-8
require 'json'
require_relative "../../../content/languages"
require_relative "../../../content/quiz_pl_wikidata"
require_relative "../../../content/quiz_witcher_pl"
def assert(value, message); raise message unless value; end
reference = JSON.parse(File.read(File.expand_path('../../fixtures/quiz/questions.json', __dir__), encoding: 'UTF-8'))
pack_ids = %w[quiz.wikidata.pl quiz.witcher.pl quiz.witcher.g.pl quiz.witcher.b.pl]
data = pack_ids.to_h do |id|
  expected = reference.fetch('packs').fetch(id)
  pack = GameRoomContent.registry.pack(id)
  questions = pack.data.fetch('questions')
  ids = questions.map { |question| question.fetch('id') }
  assert(pack.version == expected.fetch('version') && pack.verified?, "#{id}: version/checksum")
  assert(ids.length == expected.fetch('count') && ids.uniq == ids, "#{id}: count/duplicate IDs")
  [id, questions.to_h { |question| [question.fetch('id'), question] }]
end
all, games, books = data.values_at('quiz.witcher.pl', 'quiz.witcher.g.pl', 'quiz.witcher.b.pl')
assert((games.keys & books.keys).empty? && (games.keys + books.keys).sort == all.keys.sort, 'Incomplete/overlapping medium partition')
(games.merge(books)).each { |id, question| assert(question == all[id], 'Full/detail wording differs') }
general = data.fetch('quiz.wikidata.pl')
assert(general.values.none? { |question| question['review_required'] }, 'Unresolved editorial notes entered the released set')
# Confirmed key mistakes must not return; the actual wording is preserved.
{
  'polqa_00547' => ['Ile wież stoi na szachownicy na początku partii?', '4'],
  'polqa_01101' => ['Jak nazywa się równoległobok, którego długości wszystkich boków są równe?', 'romb'],
  'polqa_01779' => ['Na jakim instrumencie gra fletnista?', 'na fletni']
}.each do |id, (prompt, answer)|
  question = general.fetch(id)
  assert(question.fetch('prompt') == prompt && question.fetch('correct') == answer, "#{id}: approved PolQA decision changed")
end
%w[polqa_00012 polqa_00233].each do |id|
  assert(!general.key?(id), "#{id}: a faulty premise requiring a rewritten prompt returned")
end
# Reviewed source decisions: preserve wording except for approved minimal
# choice-list edits, corrected keys, distinct distractors and the Polsat negation.
reviewed_general = {
  'polqa_00006' => {
    'source_dataset' => 'PolQA', 'category' => 'Geografia',
    'prompt' => 'W którym państwie leży Bombaj?',
    'correct' => 'w Indiach',
    'wrong' => ['w Pakistanie', 'w Bangladeszu', 'w Nepalu']
  },
  '1z10_d29b6adc8a8b1fab' => {
    'source_dataset' => '1z10/MAUPQA', 'category' => 'Historia',
    'prompt' => 'Który polityk najdłużej pełnił funkcję prezydenta Rzeczypospolitej Polskiej?',
    'correct' => 'August Zaleski',
    'wrong' => ['Ignacy Mościcki', 'Aleksander Kwaśniewski', 'Władysław Raczkiewicz']
  },
  '1z10_eda89a6663bc42f1' => {
    'source_dataset' => '1z10/MAUPQA', 'category' => 'Kultura',
    'prompt' => 'Na którym instrumencie muzycznym grał fizyk Albert Einstein?',
    'correct' => 'Na skrzypcach',
    'wrong' => ['Na klarnecie', 'Na trąbce', 'Na flecie']
  },
  '1z10_dad26f6ca36159da' => {
    'source_dataset' => '1z10/MAUPQA', 'category' => 'Geografia',
    'prompt' => 'Ile gwiazd widnieje na fladze Panamy?',
    'correct' => 'Dwie',
    'wrong' => ['Jedna', 'Więcej niż dwie', 'Żadna']
  },
  'milionerzy_c894a05703b826b0' => {
    'source_dataset' => 'Milionerzy/Polsat', 'category' => 'Geografia',
    'prompt' => 'Nie można powiedzieć o Morzu Martwym, że jest:',
    'correct' => 'częścią Morza Czerwonego',
    'wrong' => ['mocno zasolone', 'położone w depresji', 'wydłużone południkowo']
  }
}
reviewed_general.each do |id, expected|
  question = general.fetch(id)
  expected.each { |field, value| assert(question.fetch(field) == value, "#{id}: reviewed #{field} changed") }
end
%w[74a52fd22210 b22e943857b8 7b0b05c80ea6].each { |id| assert(books.key?(id), 'Loredo book village moved into games') }
assert(books['74a52fd22210']['correct'] == 'wieś' && !books['74a52fd22210']['wrong'].include?('wioska'), 'Two synonymous correct choices')
%w[7a193c109c77 7bfa3a3165f8 86277e2087bb].each { |id| assert(games[id]['prompt'].include?('Carys') && games[id]['prompt'].include?('Hail'), 'Carys confused with Cerys') }
%w[86185faaec88 33a78b6ff1ee].each { |id| assert(games[id]['correct'] == 'GWINT: Wiedźmińska Gra Karciana', 'Valid Gwent answer replaced') }
puts 'Reviewed quiz questions: fixture counts/versions, Polish source decisions and Witcher full/detail agreement: OK'
