require_relative '../../support/audio_ball_point_audio'
require_relative '../../../lib/game_sound_output'

module AudioBallPointTest
  def self.trace(hidden:)
    klass = Class.new(Program)
    klass.define_singleton_method(:normalized_settings) { {'background_game_sounds' => 'audio'} }
    program = klass.new
    covered = false
    output = GameRoomSoundOutput.new(program, audio_game: true, covered: -> { covered })
    audio = GameRoomAudioBall::Audio.new(program, clock: -> { program.now }, rng: Random.new(7))
    audio.point([2, 1], sets: [0, 0], set_finished: false, winner: 0, viewer: 0, finished: false)
    levels = []
    begin
      (0..80).each do |step|
        program.now = step / 10.0
        covered = hidden && step.between?(1, 20)
        output.tick
        audio.tick
        levels << program.sounds.transform_values(&:volume) if program.events.last&.first == 'pong_scores'
      end
      [program.events.dup, levels]
    ensure
      audio.close
      output.close
    end
  end
  visible, visible_levels = trace(hidden: false)
  hidden, hidden_levels = trace(hidden: true)
  assert(visible == hidden, 'Background muting changed announcement order or timing / service readiness')
  assert(visible_levels.any? { |levels| levels['pong_scores'].positive? }, 'Visible reference did not play the score')
  assert(hidden_levels.all? { |levels| levels['pong_scores'] == 0 }, 'Score queued before switching away became audible after return')
  puts 'PASS Audio Ball background sound: recordings keep identical clocks, hidden pending scores do not return as a backlog'

  program_class = Class.new(Program)
  program_class.define_singleton_method(:normalized_settings) { {'background_game_sounds' => 'audio'} }
  program = program_class.new
  covered = false
  output = GameRoomSoundOutput.new(program, audio_game: true, covered: -> { covered })
  audio = GameRoomAudioBall::Audio.new(program, clock: -> { program.now })
  flight = {'phase' => 'flying', 'shot' => 'up', 'position' => 12.5, 'turn' => 1, 'goal' => nil}
  begin
    ball = program.sounds.fetch('audio_ball_up')
    ball.duration = 60
    audio.update(flight, viewer: 0)
    covered = true
    output.tick
    program.now += 0.1
    audio.update(flight, viewer: 0)
    assert(ball.playing? && ball.volume == 0 && ball.plays == 1, 'Background mute paused or restarted Audio Ball flight')
    covered = false
    output.tick
    audio.update(flight, viewer: 0)
    assert(ball.playing? && ball.volume > 0 && ball.plays == 1 && ball.seeks == [0], 'Returning rewound Audio Ball flight')
    covered = true
    audio.prepare(1, viewer: 0)
    audio.update(flight.merge('phase' => 'prepared'), viewer: 0)
    cue = program.sounds.fetch('audio_ball_prepare')
    assert(cue.playing? && cue.volume == 0, 'Background mute paused the preparation recording')
    audio.update(flight, viewer: 0, paused: true)
    assert(program.sounds.values.none?(&:playing?), 'Actual Audio Ball pause stopped working')
  ensure
    audio.close
    output.close
  end
  puts 'PASS Audio Ball: background flight/preparation stay running silently without restart or rewind'
end
