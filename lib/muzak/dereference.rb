module Muzak
  class Dereference
    attr_reader :name, :count

    def initialize(name, count: 1)
      @count = count
      @name  = name.to_s
    end

    def validate
      # no op
    end

    def to_s
      s = "(#{name})"
      s << " x#{count}" unless count == 1
      s
    end

    def run(ctx)
      sym = Array(ctx.lookup_symbol(name))

      count.times.flat_map do
        sym.flat_map{ |w| w.run(ctx) }
      end
    end
  end
end
