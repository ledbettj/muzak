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

    def initialize(opts = {})
      @ctx = Muzak::Context.new

      @format = WaveFile::Format.new(:mono, :pcm_16, @ctx.sample_rate)
      @buffer_format = WaveFile::Format.new(:mono, :float,  @ctx.sample_rate)
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
      parse(text).flat_map do |object|
        object.samples(@ctx)
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
