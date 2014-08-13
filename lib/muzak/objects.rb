module Muzak
  class Note
    attr_reader :name, :octave, :timing

    def initialize(n)
      @name   = n[:name]
      @timing = (n[:timing] || 1).to_i

      @relative = n[:octave].nil? || %w(+ -).include?(n[:octave].to_s[0])
      @octave   = n[:octave].to_i
    end

    def relative_octave?
      @relative
    end

    def samples(ctx)
      frequency   = ctx.frequency_for(self)
      duration    = ctx.duration_for(self)
      frame_count = (duration * ctx.sample_rate).to_i
      cycles_per_frame = frequency /  ctx.sample_rate

      i = 2 * Math::PI * cycles_per_frame
      phase = 0

      frame_count.times.map do
        sample = Math.sin(phase)
        phase += i
        sample
      end
    end
  end

  class Chord
    attr_reader :notes

    def initialize(notes)
      @notes = notes
    end

    def samples(ctx)
      # TODO: this is horribly broken and sounds awful
      individual = notes.map{ |n| n.samples(ctx) }
      aggregate  = []

      individual.each do |s|
        s.each_with_index do |value, i|
          aggregate[i] ||= 0
          aggregate[i] += value
        end
      end

      m = aggregate.max{|v| v.abs }.abs
      (1..aggregate.length - 1).each do |i|
        aggregate[i] /= m
      end if m > 1.0

      aggregate
    end
  end

  class NoteList
    attr_reader :notes

    def initialize(notes)
      @notes = notes
    end

    def samples(ctx)
      notes.flat_map { |n| n.samples(ctx) }
    end
  end
end
