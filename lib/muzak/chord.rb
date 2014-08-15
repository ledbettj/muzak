module Muzak
  class Chord
    attr_reader :notes, :count, :octave, :timing

    def initialize(ch, count: 1)
      @count = count
      @notes = ch[:notes].map{|n| Note.new(n)}
      @timing = (ch[:timing] || 1).to_i
      @octave = ch[:octave].to_i
    end

    def validate
      notes.each do |n|
        raise ValidationError.new("'#{self}' : Notes inside chords can't have timing.") if n.timing != 1
      end
    end

    def to_s
      s = "<#{notes.join(' ')}>"
      s << "^#{octave}" unless octave.zero?
      s << ",#{timing}" unless timing == 1
      s << " x#{count}" unless count == 1

      s
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
end
