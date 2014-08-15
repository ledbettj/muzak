module Muzak
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

    def validate
      what.each(&:validate)
    end

    def run(ctx)
      count.times.flat_map do
        what.flat_map { |w| w.run(ctx) }
      end
    end
  end
end
