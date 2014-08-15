require 'muzak/audio_filter'

module Muzak
  class Filter
    attr_reader :name, :args, :statements
    def initialize(name, args, stmts)
      args = [args] if args.is_a?(Hash)
      args = [] if args.nil?

      @name       = name.to_s
      @args       = args.each_with_object({}) do |a, h|
        h[a[:arg][:name].to_sym] = a[:arg][:value].to_f
      end
      @statements = stmts
    end

    def validate
      raise ValidationError, "Error: '#{name}' is not a filter'" unless AudioFilter.find(name)
      statements.each(&:validate)
    end

    def run(ctx)
      samples = statements.flat_map{ |s| s.run(ctx) }
      AudioFilter.find(name).transform(samples, args)
    end
  end
end
