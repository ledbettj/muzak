module Muzak
  class Note
    attr_reader :name, :octave, :timing, :count

    # for x [0,1] this function builds quickly from 0 to 1, then decays to
    # about 0.4.  We use it to scale the static waveform produced by a single
    # note to make the note sound a little better.
    SCALE = ->(x){ (4.0 * x) ** (0.25) - (x ** 2) }

    def initialize(n, count: 1)
      @count = count
      @name = n[:name].to_s
      @octave = n[:octave].to_i
      @timing = (n[:timing] || 1).to_i
    end

    def to_s
      s = "#{name}"
      s << "^#{octave}" unless octave.zero?
      s << ",#{timing}" unless timing == 1
      s << " x#{count}" unless count == 1
      s
    end

    def validate
      raise ValidationError, "Timing can't be zero" if timing.zero?
    end

    def run(ctx)
      frequency  = ctx.frequency_for(self)
      duration   = ctx.duration_for(self)
      frame_cnt  = (duration * ctx.sample_rate).to_i
      cycles_per = frequency / ctx.sample_rate

      count.times.flat_map do
        iter  = 2 * Math::PI * cycles_per
        phase = 0

        frame_cnt.times.map do |i|
          sample = Math.sin(phase)
          phase += iter
          SCALE.(i.to_f / frame_cnt) * sample
        end
      end
    end
  end
end
