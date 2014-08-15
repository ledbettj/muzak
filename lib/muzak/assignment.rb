module Muzak
  class Assignment
    attr_reader :name, :value

    def initialize(name, value)
      @name = name.to_s
      @value = value
    end

    def to_s
      "let #{name} = #{value}"
    end

    def validate
      Array(value).each(&:validate)
    end

    def run(ctx)
      ctx.define_symbol(name, value)
      []
    end
  end
end
