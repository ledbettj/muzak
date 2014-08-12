#!/usr/bin/env ruby
require 'wavefile'
require 'securerandom'
require 'readline'
require 'trollop'
require 'rbconfig'

class Muzak
  attr_accessor :format, :buffer_format
  attr_accessor :sample_rate, :bpm

  def initialize(opts = {})
    @bpm    = opts[:bpm]    || 120
    @octave = opts[:octave] || 4
    @sample_rate = 22_050
    @format = WaveFile::Format.new(:mono, :pcm_16, sample_rate)
    @buffer_format = WaveFile::Format.new(:mono, :float,  sample_rate)

    build_freq
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
    linux? ?  `aplay -q #{f}` : `afplay #{f}`
  end

  def repl
    while (line = Readline.readline('muzak> ', true))
      line.chomp!
      line.strip!
      self.play(line)
    end
  end

  private

  def linux?
    RbConfig::CONFIG['host_os'] =~ /linux/
  end

  def samples(text)
    parse(text).flat_map do |note|
      samples_for(note)
    end
  end

  def samples_for(note)
    frequency = frequency_for(note[:frequency])
    duration  = note[:duration]

    total_frames = (seconds_per(duration) * sample_rate).to_i
    cycles_per_frame = frequency / sample_rate

    increment = 2 * Math::PI * cycles_per_frame
    phase = 0

    total_frames.times.map do
      sample = Math.sin(phase)
      phase += increment
      sample
    end
  end

  def seconds_per(duration)
    (240.0/@bpm) * duration
  end

  def frequency_for(f)
    @tbl[f] or raise ArgumentError, f
  end

  def parse(str)
    str = str.gsub(/[^A-G0-9#b ]+/, '')
    # Note, optionally sharp or flat, followed by duration in 1/s.
    str.scan(/([A-G ][#b]?)(\d*)/).map do |note, dur|
      dur = dur.to_i
      dur = dur.zero? ? 1 : dur
      { frequency: note, duration: 1.0 / dur }
    end
  end

  R = 1.05946309436
  def build_freq
    c = 16.35 * (2 ** @octave)

    @tbl = {
      ' ' => 0.0,
      'C' => c,
    }

    freq = c

    [['C#', 'Db'], 'D', ['D#', 'Eb'], 'E', 'F', ['F#', 'Gb'], 'G', ['G#', 'Ab'], 'A', ['A#', 'Bb'], 'B'].each do |n|
      freq *= R
      Array(n).each{ |nx| @tbl[nx] = freq }
    end
  end
end


opts = Trollop::options do
  opt :bpm,    "Beats per minute (default 240)", type: :int, default: 240
  opt :octave, "Octave to use (default 4)",      type: :int, default: 4
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
