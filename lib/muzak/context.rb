module Muzak
  class Context
    attr_accessor :octave, :bpm, :sample_rate

    def initialize(octave: 4, bpm: 240, sample_rate: 22_050)
      @octave = octave
      @bpm    = bpm
      @sample_rate = sample_rate

      @symtab = {}
    end

    def frequency_for(note)
      TABLE[octave_for(note)][note.name.to_s]
    end

    def duration_for(note)
      (240.0 / bpm) / note.timing
    end

    def octave_for(note)
      note.octave + (note.relative_octave? ? @octave : 0)
    end

    def define_symbol(ident, chord)
      @symtab[ident] = chord
    end

    def lookup_symbol(ident)
      @symtab[ident]
    end

    R = 1.05946309436
    def self.build_freq
      tbl = []

      (0..8).each do |o|
        c = 16.35 * (2 ** o)
        freq = c

        tbl.push(
          '_' => 0.0,
          'C' => c
        )

        [['C#', 'Db'], 'D', ['D#', 'Eb'], 'E', 'F', ['F#', 'Gb'], 'G', ['G#', 'Ab'], 'A', ['A#', 'Bb'], 'B'].each do |n|
          freq *= R
          Array(n).each{ |nx| tbl.last[nx] = freq }
        end
      end

      tbl
    end

    TABLE = build_freq

  end
end
