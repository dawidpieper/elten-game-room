require_relative '../../lib/game_sound_output'
require_relative '../../lib/game_sounds'

def assert(value, message); raise message unless value; end
def _(text); text; end

class OutputTestSound
  attr_accessor :volume, :done, :closed
  attr_reader :started_at_volume
  def initialize(volume); @volume = @started_at_volume = volume; end
  def finished?; !!@done; end
  def closed?; !!@closed; end
end
class OutputTestProgram
  class << self; attr_accessor :settings; end
  def self.normalized_settings; settings; end
  def play_sound_from_asset(_name, volume: 1.0, **_options); OutputTestSound.new(volume); end
end

$activecontrols = $lastactivecontrols = nil
program = OutputTestProgram.new
%w[never audio all].each do |mode|
  [false, true].each do |audio_game|
    settings = {'background_game_sounds' => mode, 'background_table_speech' => true, 'background_turn_sound' => true}
    OutputTestProgram.settings = settings
    covered = false
    output = GameRoomSoundOutput.new(program, audio_game: audio_game, covered: -> { covered })
    muted = mode == 'all' || mode == 'audio' && audio_game
    begin
      loop_sound = OutputTestSound.new(0.4)
      GameRoomSoundOutput.apply(program, loop_sound, 0.4, continuous: true)
      effect = GameRoomSoundOutput.play(program, 'play', volume: 0.6)
      assert(loop_sound.volume == 0.4 && effect.volume == 0.6, 'Foreground audio changed')
      covered = true
      output.tick
      assert(loop_sound.volume == (muted ? 0.0 : 0.4), "#{mode}/#{audio_game}: existing loop not gated")
      assert(effect.volume == (muted ? 0.0 : 0.6), 'Existing one-shot not gated')
      next_effect = GameRoomSoundOutput.play(program, 'play', volume: 0.7)
      assert(next_effect.started_at_volume == (muted ? 0.0 : 0.7), 'One-shot leaked an audible start')
      %w[connect disconnect chatmsg notice table_notice invitation_rejected ding].each do |name|
        sound = GameRoomSounds.play_asset(program, name, 0.8)
        assert(sound.volume == 0.8, "Excluded #{name} was muted")
      end
      assert(GameRoomBackgroundPolicy.speech?(program, covered: true), 'Audio setting changed speech')
      assert(GameRoomBackgroundPolicy.turn_sound?(program, covered: true), 'Audio setting changed turn ding')
      covered = false
      output.tick
      assert(loop_sound.volume == 0.4, 'Continuous stream did not restore its original gain')
      assert(next_effect.volume == (muted ? 0.0 : 0.7), 'Old one-shot became audible on return')
      GameRoomSoundOutput.apply(program, next_effect, 0.3, restart: true)
      assert(next_effect.volume == 0.3, 'New use of a pooled stream stayed muted')
      next_effect.done = true
      effect.closed = true
      output.tick
      assert(output.instance_variable_get(:@voices).keys == [loop_sound], 'Finished/closed voices retained')
      assert(settings == {'background_game_sounds' => mode, 'background_table_speech' => true, 'background_turn_sound' => true}, 'Gating rewrote preferences')
    ensure
      output.close
    end
  end
end

OutputTestProgram.settings = {'background_game_sounds' => 'all'}
rounded = OutputTestSound.new(0.2)
rounded.define_singleton_method(:volume) { [@volume].pack('f').unpack1('f') }
rounded.define_singleton_method(:volume=) { |value| @writes = @writes.to_i + 1; @volume = value }
rounding_output = GameRoomSoundOutput.new(program, audio_game: true, covered: -> { false })
GameRoomSoundOutput.apply(program, rounded, 0.2, continuous: true)
10.times { rounding_output.tick }
assert(rounded.instance_variable_get(:@writes) == 1, 'Float rounding caused repeated native volume writes')
rounding_output.close

old = GameRoomSoundOutput.new(program, audio_game: true, covered: -> { false })
replacement = GameRoomSoundOutput.new(program, audio_game: false, covered: -> { true })
old.close
assert(GameRoomSoundOutput.current(program).equal?(replacement), 'Closing an old screen removed the new output')
foreground = GameRoomBackgroundPolicy.method(:window_foreground?)
begin
  GameRoomBackgroundPolicy.define_singleton_method(:window_foreground?) { false }
  $activecontrols = [Object.new.tap do |control|
    control.define_singleton_method(:game_room_hotkeys_active?) { true }
    control.define_singleton_method(:game_room_program) { program }
  end]
  assert(replacement.muted?, 'OS focus loss was overridden by old active form')
  GameRoomBackgroundPolicy.define_singleton_method(:window_foreground?) { true }
  assert(!replacement.muted?, 'Owned settings/help did not remain in the current game context')
ensure
  GameRoomBackgroundPolicy.define_singleton_method(:window_foreground?, foreground)
  $activecontrols = nil
  replacement.close
end
assert(GameRoomSoundOutput.current(program).nil?, 'Closed output remained attached')
puts 'PASS background game audio: 3 modes, turn/realtime, immediate mute, loops, pooled effects, no backlog, exclusions, own forms and OS focus'
