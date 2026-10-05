require_relative 'game_background_policy'

# An output-only gate. Silent streams still finish on their original clock,
# so muting cannot shorten a score announcement or a serial presentation.
# The screen's existing UI ticks maintain it; there is no extra worker/timer.
class GameRoomSoundOutput
  def self.current(program)
    program.instance_variable_get(:@game_room_sound_output)
  end

  def self.apply(program, sound, volume, continuous: false, restart: false, silent: false)
    return unless sound && sound.respond_to?(:volume=)
    output = current(program)
    if output
      output.apply(sound, volume, continuous: continuous, restart: restart, silent: silent)
    else
      sound.volume = volume
    end
  end

  def self.play(program, asset, volume: 1.0, **options)
    output = current(program)
    sound = program.play_sound_from_asset(asset, volume: output&.muted? ? 0.0 : volume, **options)
    apply(program, sound, volume, restart: true)
    sound
  end

  def initialize(program, audio_game:, covered:)
    @program, @audio_game, @covered = program, audio_game, covered
    @voices = {}
    program.instance_variable_set(:@game_room_sound_output, self)
  end

  def muted?
    !GameRoomBackgroundPolicy.game_sounds?(@program, audio_game: @audio_game, covered: @covered.call)
  end

  def apply(sound, volume, continuous:, restart:, silent:)
    voice = @voices[sound] ||= {volume: volume, continuous: continuous, suppressed: false}
    voice[:volume], voice[:continuous] = volume, continuous
    voice[:suppressed] = silent if restart
    muted = muted?
    voice[:suppressed] ||= silent || (!continuous && muted)
    sound.volume = muted || voice[:suppressed] ? 0.0 : volume
  end

  def tick
    muted = muted?
    @voices.delete_if do |sound, voice|
      next true if sound.respond_to?(:closed?) && sound.closed?
      next true if !voice[:continuous] && sound.respond_to?(:finished?) && sound.finished?
      voice[:suppressed] = true if muted && !voice[:continuous]
      volume = muted || voice[:suppressed] ? 0.0 : voice[:volume]
      # Native audio returns a 32-bit float; tiny rounding differences must
      # not cause another write on every UI tick.
      sound.volume = volume if (sound.volume - volume).abs > 0.000001
      false
    end
  end

  def close
    @program.remove_instance_variable(:@game_room_sound_output) if self.class.current(@program).equal?(self)
    @voices.clear
  end
end
