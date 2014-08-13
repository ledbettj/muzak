module Muzak
  class Note
    attr_reader :name, :octave, :timing

    def initialize(n)
      @name   = n[:name].to_s
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
    attr_reader :notes, :count

    def initialize(notes, count: 1)
      @notes = notes
      @count = count
    end

    def samples(ctx)
      count.times.flat_map{ sample_once(ctx) }
    end

    private

    def sample_once(ctx)
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
    attr_reader :notes, :count

    def initialize(notes, count: 1)
      @notes = notes
      @count = count
    end

    def samples(ctx)
      count.times.flat_map{ sample_once(ctx) }
    end

    private

    def sample_once(ctx)
      notes.flat_map { |n| n.samples(ctx) }
    end
  end

  class Command
    attr_reader :name
    attr_reader :value

    def initialize(h)
      @name  = h[:command].to_s
      @value = h[:value].to_i
    end

    def samples(ctx)
      ctx.send("#{@name}=", @value)
      []
    end
  end

  class Assignment
    attr_reader :identifier
    attr_reader :chord
    def initialize(a)
      @identifier = a[:identifier].to_s
      @chord = Chord.new(a[:chord])
    end

    def samples(ctx)
      ctx.define_symbol(identifier, chord)

      []
    end
  end

  class Invocation
    attr_reader :identifier
    attr_reader :count
    def initialize(n, count: 1)
      @identifier = n[:identifier].to_s
      @count = count
    end

    def samples(ctx)
      count.times.flat_map{ sample_once(ctx) }
    end

    private
    def sample_once(ctx)
      ctx.lookup_symbol(identifier).samples(ctx)
    end
  end
end
