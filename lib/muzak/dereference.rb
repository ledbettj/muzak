module Muzak
  class Dereference
    attr_reader :name, :count, :timing, :octave

    def initialize(d, count: 1)
      @count = count
      @name  = d[:name].to_s
      @octave = d[:octave].to_i
      @timing = (d[:timing] || 1).to_i
    end

    def validate
      # no op
      # but really we should have a context here and do the check
      # that we do below in run() prior to generating samples.
    end

    def to_s
      s = "(#{name})"
      s << " x#{count}" unless count == 1
      s
    end

    def run(ctx)
      sym = Array(ctx.lookup_symbol(name))

      if sym.length > 1 && (timing != 1)
        raise ValidationError, "#{self} Cannot change timing for a sound list"
      end

      # TODO: implement timing change for chords

      ctx.octave += octave

      rc = count.times.flat_map do
        sym.flat_map{ |w| w.run(ctx) }
      end

      ctx.octave -= octave

      rc
    end
  end
end
