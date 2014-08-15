module Muzak
  class Command
    attr_reader :type, :value

    def initialize(type, value = nil)
      @type  = type.to_s.to_sym
      @value = value
    end

    def run(ctx)
      case type
      when :bpm
        ctx.bpm = value.to_i
      when :octave_up
        ctx.octave += 1
      when :octave_down
        ctx.octave -= 1
      when :octave
        ctx.octave = value.to_i
      end

      []
    end
  end
end
