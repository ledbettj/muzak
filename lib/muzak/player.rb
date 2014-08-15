#!/usr/bin/env ruby
require 'wavefile'
require 'securerandom'
require 'readline'
require 'rbconfig'

require 'muzak/parser'
require 'muzak/context'

module Muzak
  class Player
    attr_accessor :format, :buffer_format

    CHORDS = {
      'C'   => 'C E G',
      'Cm'  => 'C Eb G',
      'D'   => 'D F# A',
      'Dm'  => 'D F A',
      'E'   => 'E G# B',
      'Em'  => 'E G B',
      'F'   => 'F A C',
      'Fm'  => 'F Ab C',
      'G'   => 'G B D',
      'Gm'  => 'G Bb D',
      'A'   => 'A C# E',
      'Am'  => 'A C E',
      'A7'  => 'A C# E G'
    }

    def initialize(opts = {})
      @ctx = Muzak::Context.new(bpm: opts[:bpm], octave: opts[:octave])

      @format = WaveFile::Format.new(:mono, :pcm_16, @ctx.sample_rate)
      @buffer_format = WaveFile::Format.new(:mono, :float,  @ctx.sample_rate)

      load_chords
    end


    def write(filename, text)
      s = samples(text)
      WaveFile::Writer.new(filename, format) do |w|
        w.write WaveFile::Buffer.new(s, buffer_format)
      end if s.any?

      s.any?
    end

    def play(text)
      f = nil
      f = "/tmp/#{SecureRandom.uuid}.wav" while f.nil? || File.exists?(f)

      if write(f, text)
        linux? ?  `aplay -q #{f}` : `afplay #{f}`
      end
    end

    def repl
      while (line = Readline.readline('muzak> ', true))
        line.chomp!
        line.strip!
        self.play(line)
      end
    end

    private

    def load_chords
      play(CHORDS.map{ |k, v| "let #{k} = <#{v}>"}.join(';'))
    end

    def linux?
      RbConfig::CONFIG['host_os'] =~ /linux/
    end

    def samples(text)
      parse(text).flat_map do |object|
        object.run(@ctx)
      end
    end

    def parse(str)
      parser.parse_and_transform(str)
    rescue Parslet::ParseFailed => e
      STDERR.write("Failed to parse: #{e.message}\n")
      []
    end

    def parser
      @parser ||= Muzak::Parser.new
    end
  end
end
