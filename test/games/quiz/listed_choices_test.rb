# encoding: UTF-8
require_relative '../../../content/languages'
require_relative '../../../content/quiz_pl_wikidata'

def assert(value, message); raise message unless value; end

pack = GameRoomContent.registry.pack('quiz.wikidata.pl')
questions = pack.data.fetch('questions').to_h { |question| [question.fetch('id'), question] }

# These prompts used to name just three possibilities even though players
# receive four answers. Keep the approved short, natural formulations.
{
  'polqa_01980' => 'Która z rzek jest najdłuższa?',
  'polqa_01943' => 'W którym państwie leży uzdrowisko Podiebrady?',
  'polqa_01920' => 'Który z tych arkuszy papieru ma najmniejsze wymiary?',
  '1z10_dad26f6ca36159da' => 'Ile gwiazd widnieje na fladze Panamy?',
  '1z10_2bfef1efbf270a8a' => 'Która z konstytucji została uchwalona po II wojnie światowej?',
  '1z10_2a236e101b12d9a8' => 'Który z tych aktorów nie zagrał Robin Hooda?',
  'polqa_01098' => 'Który z tych pisarzy nie dostał Nagrody Nobla?',
  '1z10_aacab8090dd435e4' => 'Woods, irons i wedges to rodzaje czego w golfie?'
}.each do |id, prompt|
  assert(questions.fetch(id).fetch('prompt') == prompt, "#{id}: embedded alternatives returned or approved wording changed")
end

# Removing the three-item enumeration must not leave an obsolete pronoun,
# a mismatched case, or make a fourth choice invalidate the answer key.
{
  'polqa_01943' => ['w Czechach', ['na Słowacji', 'w Austrii', 'na Węgrzech']],
  'polqa_01977' => ['zwierzęcych i roślinnych', ['tylko zwierzęcych', 'tylko roślinnych', 'ani zwierzęcych, ani roślinnych']],
  'polqa_03865' => ['Ocean Indyjski', ['Ocean Atlantycki', 'Ocean Spokojny', 'Wszystkie mają taką samą powierzchnię']],
  '1z10_7131315df2b5ea27' => ['Uzbekistan', ['Kirgistan', 'Turkmenistan', 'Tadżykistan']],
  'polqa_06359' => ['malarzem', ['pisarzem', 'reżyserem filmowym', 'żadnym z wymienionych']],
  '1z10_aacab8090dd435e4' => ['Kijów golfowych', ['Piłek golfowych', 'Dołków golfowych', 'Uderzeń golfowych']]
}.each do |id, (correct, wrong)|
  question = questions.fetch(id)
  assert(question.fetch('correct') == correct && question.fetch('wrong') == wrong, "#{id}: contextual answer forms changed")
end
assert(questions.fetch('1z10_7131315df2b5ea27').fetch('prompt') ==
  'Które z tych państw graniczy ze wszystkimi pozostałymi?', 'Comparison still refers to only two other states')

# Lists that are genuine clues, quotations, titles or already contain every
# answer are not the defect being fixed. Do not mechanically strip them.
{
  'polqa_00799' => 'Basen Labradorski, Gujański, Angolski – to baseny którego oceanu?',
  'polqa_05468' => 'Który wyraz w zdaniu: „Przed szkołą stał autokar” jest przyimkiem?',
  'polqa_05793' => 'Szrenica to szczyt w Tatrach, Beskidach, Karkonoszach czy w Bieszczadach?',
  '1z10_a853db0f6eec3c6d' => 'Który tytułowy bohater jest najwyższy wzrostem w serii komiksów Tytus, Romek i Atomek?'
}.each do |id, prompt|
  assert(questions.fetch(id).fetch('prompt') == prompt, "#{id}: a meaningful clue or complete list was removed")
end

puts 'Quiz listed choices: minimal wording, dependent answers and meaningful clues: OK'
