module Muzak
  class AudioFilter
    def self.filters
      @filters ||= {}
    end

    def self.find(name)
      filters[name]
    end

    def self.filter(name, &blk)
      filters[name] = AudioFilter.new(&blk)
    end

    def initialize(&blk)
      @transform = blk
    end

    def transform(samples, args = {})
      @transform.call(samples, args)
    end

    # filter that does nothing
    filter('null') { |samples, args| samples }

    filter('clip') do |samples, args|
      threshold = args[:threshold] || 0.5
      samples.map do |value|
        if value > threshold
          threshold
        elsif value < -threshold
          -threshold
        else
          value
        end
      end
    end

    filter('compress') do |samples, args|
      threshold = args[:threshold] || 0.5
      scale     = args[:scale]     || 0.25

      samples.map do |value|
        if value > threshold
          threshold + (value - threshold) * scale
        elsif value < -threshold
          -threshold - (value.abs - threshold) * scale
        else
          value
        end
      end
    end
  end
end
