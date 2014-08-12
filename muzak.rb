#!/usr/bin/env ruby
require 'wavefile'
require 'securerandom'
require 'readline'
require 'trollop'

class Muzak
  attr_accessor :format, :buffer_format, :sample_rate

  def initialize(opts = {})
    @time_unit = opts[:time] || 1.0
    @sample_rate = 22_050
    @format = WaveFile::Format.new(:mono, :pcm_16, sample_rate)
    @buffer_format = WaveFile::Format.new(:mono, :float,  sample_rate)
  end


  def write(filename, text)
    WaveFile::Writer.new(filename, format) do |w|
      w.write WaveFile::Buffer.new(samples(text), buffer_format)
    end
  end

  def play(text)
    f = nil
    f = "/tmp/#{SecureRandom.uuid}.wav" while f.nil? || File.exists?(f)

    write(f, text)
    `afplay #{f}`
  end

  def repl
    while (line = Readline.readline('muzak> ', true))
      line.chomp!
      line.strip!
      self.play(line)
    end
  end

  private

  def samples(text)
    parse(text).flat_map do |note|
      samples_for(note)
    end
  end

  def samples_for(note)
    frequency = frequency_for(note[:frequency])
    duration    = note[:duration]

    total_frames = (@time_unit * duration * sample_rate).to_i
    cycles_per_frame = frequency / sample_rate

    increment = 2 * Math::PI * cycles_per_frame
    phase = 0

    total_frames.times.map do
      sample = Math.sin(phase)
      phase += increment
      sample
    end
  end

  def frequency_for(f)
    case f
    when ' '        then 0.0
    when 'Ab'       then 415.30
    when 'A'        then 440.0
    when 'A#', 'Bb' then 466.16
    when 'B'        then 493.99
    when 'C'        then 523.25
    when 'C#', 'Db' then 554.37
    when 'D'        then 587.33
    when 'D#', 'Eb' then 622.25
    when 'E'        then 659.25
    when 'F'        then 698.46
    when 'F#', 'Gb' then 739.99
    when 'G'        then 783.99
    when 'G#'       then 830.61
    else
      raise ArgumentError, f
    end
  end

  def parse(str)
    str = str.gsub(/[^A-G0-9#b ]+/, '')
    str.scan(/([A-G ][#b]?)(\d*)/).map do |note, dur|
      dur = dur.to_i
      dur = dur.zero? ? 1 : dur
      { frequency: note, duration: 1.0 / dur }
    end
  end

end


opts = Trollop::options do
  opt :time, "Default time unit (in seconds)", type: :float, default: 1.0
end

muzak = Muzak.new(opts)

if STDIN.tty?
  puts "Enter a list of notes and beat counts."
  puts "Example: C#4Gb (play C# for 1/4 second followed by Gb for 1 second)"
  puts ""
  puts "Use a space to input a pause."
  puts "Example: C#4 4Gb"

  muzak.repl
else
  muzak.play(STDIN.read)
end
