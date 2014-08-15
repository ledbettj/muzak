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
end
