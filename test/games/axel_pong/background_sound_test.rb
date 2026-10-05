require_relative '../../support/pong_audio'

class BackgroundPongProgram < PongAudioProgram
  def self.normalized_settings; {'background_game_sounds' => 'audio'}; end
end
program = BackgroundPongProgram.new
covered = false
output = GameRoomSoundOutput.new(program, audio_game: true, covered: -> { covered })
audio = GameRoomPong::Audio.new(program)
audio.load
engine = GameRoomPong::Engine.new
engine.strike(0)
snapshot = engine.snapshot
snapshot['b'].merge!('x' => 20.0, 'y' => 5.0)
begin
  audio.update(snapshot, viewer: 0, paused: false)
  ball = program.sounds.fetch('pong_ball')
  assert(ball.playing? && ball.volume > 0, 'Reference flight did not start')
  starts = ball.plays
  position = ball.position
  covered = true
  output.tick
  5.times { audio.update(snapshot, viewer: 0, paused: false) }
  assert(ball.playing? && ball.volume == 0 && ball.plays == starts, 'Background mute paused or restarted the flight')
  covered = false
  output.tick
  audio.update(snapshot, viewer: 0, paused: false)
  assert(ball.playing? && ball.volume > 0 && ball.plays == starts && ball.position == position,
    'Returning from background restarted or rewound the ball')
  covered = true
  snapshot['fx'] = [[2, 'hit', 1, 20.0, 20.0]]
  audio.update(snapshot, viewer: 0, paused: false)
  assert(ball.playing? && ball.volume == 0, 'New background contact did not keep the continuous sound running')
  audio.update(snapshot, viewer: 0, paused: true)
  assert(!ball.playing?, 'Actual game pause stopped working')
ensure
  audio.close
  output.close
end
puts 'PASS Pong: background mute preserves the continuous flight clock; return, contact and real pause remain correct'
