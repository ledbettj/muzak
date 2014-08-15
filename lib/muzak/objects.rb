module Muzak

  class Note
    attr_reader :name, :octave, :timing, :count

    def initialize(n, count: 1)
      @count = count
      @name = n[:name].to_s
      @octave = n[:octave].to_i
      @timing = (n[:timing] || 1).to_i
    end

    def run(ctx)
      frequency  = ctx.frequency_for(self)
      duration   = ctx.duration_for(self)
      frame_cnt  = (duration * ctx.sample_rate).to_i
      cycles_per = frequency / ctx.sample_rate

      count.times.flat_map do
        iter  = 2 * Math::PI * cycles_per
        phase = 0

        frame_cnt.times.map do
          sample = Math.sin(phase)
          phase += iter
          sample
        end
      end
    end
  end

  class Chord
    attr_reader :notes, :count, :octave, :timing

    def initialize(ch, count: 1)
      @count = count
      @notes = ch[:notes].map{|n| Note.new(n)}
      @timing = (ch[:timing] || 1).to_i
      @octave = ch[:octave].to_i
    end

    def run(ctx)
      count.times.flat_map do
        individual = notes.map{ |n| run_for(n,ctx) }
        aggregate  = []

        individual.each do |samples|
          samples.each_with_index do |value, i|
            aggregate[i] ||= 0
            aggregate[i] += value
          end
        end

        max = aggregate.map{|value| value.abs}.max

        (1..aggregate.length-1).each do |index|
          aggregate[index] /= max
        end if max > 1.0

        aggregate
      end
    end

    private

    def run_for(note, ctx)
      octave = ctx.octave + self.octave + note.octave

      frequency  = Muzak::Context::TABLE[octave][note.name]
      duration   = ctx.duration_for(self)
      frame_cnt  = (duration * ctx.sample_rate).to_i
      cycles_per = frequency / ctx.sample_rate

      iter  = 2 * Math::PI * cycles_per
      phase = 0

      frame_cnt.times.map do
        sample = Math.sin(phase)
        phase += iter
        sample
      end
    end
  end

  class Dereference
    attr_reader :name, :count

    def initialize(name, count: 1)
      @count = count
      @name  = name.to_s
    end

    def run(ctx)
      sym = Array(ctx.lookup_symbol(name))

      count.times.flat_map do
        sym.flat_map{ |w| w.run(ctx) }
      end
    end
  end

  class Assignment
    attr_reader :name, :value

    def initialize(name, value)
      @name = name.to_s
      @value = value
    end

    def run(ctx)
      ctx.define_symbol(name, value)
      []
    end
  end

  class Exec
    attr_reader :what, :count
    def initialize(what)
      @count = 1

      @what = Array(what)
      if @what.last.is_a?(Hash) && @what.last.key?(:count)
        @count = @what.last[:count].to_i
        @what.pop
      end
    end

    def run(ctx)
      count.times.flat_map do
        what.flat_map { |w| w.run(ctx) }
      end
    end
  end

  class Command
    attr_reader :type, :value

    def initialize(type, value = nil)
      @type  = type.to_s.to_sym
      @value = value.to_i
    end

    def run(ctx)
      case type
      when :bpm
        ctx.bpm = value
      when :octave_up
        ctx.octave += 1
      when :octave_down
        ctx.octave -= 1
      when :octave
        ctx.octave = value
      end

      []
    end
  end
end
