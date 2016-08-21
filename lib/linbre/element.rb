require 'forwardable'

module Linbre
  module Element

    ################################################################
    # Fundamental elements: BOX, GLUE, PENALTY
    class Base
      def initialize(width:, stretch:, shrink:)
        @dimension = Dimension.new(width: width, stretch: stretch, shrink: shrink)
      end

      def type
        raise "Implement in subclass"
      end

      def glue?    ; type == :glue    ; end
      def box?     ; type == :box     ; end
      def penalty? ; type == :penalty ; end
    end

    class Glue < Base
      def_delegators :@dimension, :width, :stretch, :shrink

      def type ; :glue ; end
    end

    class Box < Base
      def_delegators :@dimension, :width
      attr_reader :value

      def initialize(width:, value:)
        @dimension = Dimension.new(width: width)
        @value = value
      end

      def type ; :box ; end
    end

    class Penalty < Base
      def_delegators :@dimension, :width
      attr_reader :penalty, :flagged

      def initialize(width:, penalty:, flagged:)
        @dimension = Dimension.new(width: width)
        @penalty, @flagged = penalty, flagged
      end

      def type ; :penalty ; end
    end

    ################################################################
    # Element size
    class Dimension
      attr_accessor :width, :stretch, :shrink

      def initialize(width: 0, stretch: 0, shrink: 0)
        @width, @stretch, @shrink = width, stretch, shrink
      end

      def +(o)
        Dimension.new(width:   self.width   + o.width,
                      stretch: self.stretch + o.stretch,
                      shrink:  self.shrink  + o.shrink)
      end

      def -(o)
        Dimension.new(width:   self.width   - o.width,
                      stretch: self.stretch - o.stretch,
                      shrink:  self.shrink  - o.shrink)
      end
    end # class Dimension

    ################################################################
    # List of elements
    class List
      def initialize
        @elements = []
      end

      def <<(element)
        @elements << element
      end

      # sum of dimension
      def dimension(from:, to:)
        # xxx: penalty should not be accumlated
        @elements[from..to].reduce(:+)
      end

      # xxx need :justify, :right, :center options.
      def store_japanese_string(string)
        string = string.gsub(/[\n\r\t 　]+/, " ")

        string.each_char do |c|
          w = if c.ascii_only? then 1 else 2 end

          @elements << Box.new(width: w, value: c)
          @elements << Glue.new(width: 1, shrink: 1, stretch: 1)
        end

        @elements.pop # Remove last glue element
        # Add unconditional break at the end of paragraph
        @elements << Glue(width: 0, shrink: Infinity, stretch: 0)
        @elements << Penaty(width: 0, penalty: -Infinity, flagged: 1)
      end

    end
  end # module Element
end # module Linbre
