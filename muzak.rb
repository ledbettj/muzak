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
    frequency = frequency_for(note)
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
    @tbl[f[:octave]][f[:name]] or raise ArgumentError, f
  end

  def parse(str)
    str = str.gsub(/[^A-G0-9#b\^,_+-]+/, '')

    str.scan(/([A-G_][#b]?)(\^[+-]{0,1}\d)?(,\d+)?/).map do |note, octave, dur|
      dur = dur.nil? ? 1 : dur[1..-1].to_i
      octave = if octave.nil?
                 @octave
               elsif octave.start_with?('^+')
                 @octave + octave[2..-1].to_i
               elsif octave.start_with?('^-')
                 @octave - octave[2..-1].to_i
               else
                 octave[1..-1].to_i
               end
      { name: note, octave: octave, duration: 1.0 / dur }
    end
  end

  R = 1.05946309436
  def build_freq
    @tbl = []

    (0..8).each do |o|
      c = 16.35 * (2 ** o)
      freq = c

      @tbl.push(
        '_' => 0.0,
        'C' => c
      )

      [['C#', 'Db'], 'D', ['D#', 'Eb'], 'E', 'F', ['F#', 'Gb'], 'G', ['G#', 'Ab'], 'A', ['A#', 'Bb'], 'B'].each do |n|
        freq *= R
        Array(n).each{ |nx| @tbl.last[nx] = freq }
      end
    end
  end
end


opts = Trollop::options do
  opt :bpm,    "Beats per minute (default 240)", type: :int, default: 240
  opt :octave, "Octave to use (default 4)",      type: :int, default: 4
end

muzak = Muzak.new(opts)

if STDIN.tty?
  puts "Syntax: <Note>[^Octave][,Duration] - Octave and Duration optional."
  puts "\tOctave - absolute number 0-8, or relative number like +2 or -1"
  puts "Examples:"
  puts "\tBb     - B flat whole note in default octave"
  puts "\tBb^+1  - B flat whole note up one octave"
  puts "\tC#,4   - C# quarter note in default octave"
  puts "\tA^3,2  - A half note in 3rd octave"
  puts "\tF^5,16 - F sixteenth note in 5th octave"
  puts "\t_,16   - rest for sixteenth note"
  puts ""
  puts "\tA# A G F A# A G F A# A A# B C^+1 A G F - Meowmix theme song."
  muzak.repl
else
  muzak.play(STDIN.read)
end
