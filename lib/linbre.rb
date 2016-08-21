module Linbre
  Infinity = 10000

  class ActiveNode
    def initialize(position:, demerits:, ratio:, line:,
                   fitness_class:, totals:, previous:)
      @position      = position # element position
      @demerits      = demerits
      @ratio         = ratio
      @line          = line # line number
      @fitness_class = fitness_class
      @totals        = totals || Total.new
      @previous      = previous # previous line's active node
    end
  end

  class ActiveNodeTree
  end

  class FitnessClass
    def initialize(ratio)
      @current_class =
        if ratio < -0.5
          0
        elsif ratio <= 0.5
          1
        elsif ratio <= 1
          2
        else
          3
        end
    end

    def to_i
      @current_class
    end
  end

  class LineBreak
    def initialize(nodes, lines, settings = nil)
      @nodes = nodes

      @options = Struct.new(:line, :flagged, :fitness).new(
        settings&.demerits&.line    || 10,
        settings&.demerits&.flagged || 100,
        settings&.demerits&.fitness || 3000
      )

      @activeNodes = ActiveNode.new
      @line_lengths = lines
      @sum = Total.new
    end

    def find_best_active_node(elements, line_width_list)
      # Add an active node for the start of the paragraph.
      @active_nodes.push(ActiveNode.empty_node)

      elements.each_with_index do |el, index|
        case el.type
        when :box
          # Do nothing. BOX is not a valid line-break point.

        when :glue
          # GLUE just after BOX is a line-break candidate.
          if index > 0 && elements[index - 1].box?
            update_active_nodes(@active_nodes, elements, index)
          end

        when :penalty
          # PENALTY is a line-break candidate.
          if el.penalty != Infinity
            update_active_nodes(@active_nodes, elements, index)
          end
        end
      end

      # Find the best active node (the one with the least total demerits.)
      return @active_nodes.min {|a,b| a.demerits <=> b.demerits}.first

    end # find_best_active_node

    ################################################################
    private

    def create_candidate(ratio, active, elements, index)
      el = elements[index]

      badness       = 100 * (ratio.abs ** 3)
      demerits      = (@options.demerits.line + badness) ** 2
      fitness_class = FitnessClass.new(ratio).to_i

      if el.penalty?

        # Positive penalty
        if el.penalty >= 0
          demerits += (el.penalty ** 2)

        # Negative penalty but not a forced break
        elsif el.penalty != -Infinity
          demerits -= (el.penalty ** 2)
        end

        if elements[active.position].penalty?
          demerits += @options.demerits.flagged * el.flagged *
                      elements[active.position].flagged
        end
      end

      # Add a fitness penalty to the demerits if the fitness
      # classes of two adjacent lines differ too much.
      if (fitness_class - active.fitness_class).abs > 1
        demerits += @options.demerits.fitness
      end

      # Add the total demerits of the active node to get the total
      # demerits of this candidate node.
      demerits += active.demerits

      ActiveNode.new(position:      index,
                     demerits:      demerits,
                     ratio:         ratio,
                     line:          active.lineno + 1,
                     fitness_class: fitness_class,
                     previous:      active)

    end # create_candidate


    def update_active_nodes(active_nodes, elements, index)
      active = active_nodes.first
      line_width = 80

      # candidates for each fitness-class 0..3
      candidates = []

      while active
        ratio  = compute_ratio(active.position, index, active, line_width)
        lineno = active.lieno

        # Deactive nodes when the distance between the current
        # active node and the current node becomes too large
        # (i.e. it exceeds the stretch limit and the stretch ratio
        # becomes negative) or when the current node is a forced
        # break (i.e. the end of the paragraph when we want to
        # remove all active nodes, but possibly have a final
        # candidate active node - if the paragraph can be set using
        # the given tolerance value.)
        if ratio < -1 || (el.penalty? && el.penalty == -Infinity)
          active_nodes.remove(active)
        end

        # If the ratio is within the valid range of -1 <= ratio <=
        # tolerance calculate the total demerits and record a
        # candidate active node.
        if -1 <= ratio && ratio <= @options.tolerance
          candidate = create_candidate(ratio, active, elements, index)

          # Only store the best candidate for the target fitness class
          if candidates[candidate.fitness_class].nil? ||
             candidate.demerits < candidates[candidate.fitness_class].demerits
            candidates[candidate.fitness_class] = candidate
          end
        end

        active = active.next

        # Insert new candidate active nodes in the active_nodes before
        # moving on to the active nodes for the next line.
        if active.nil? || active.lineno > lineno
          candidates.each_with_index do |cand|
            if cand && cand.demerits < Infinity
              if active != nil
                active_nodes.insert_before(active, cand)
              else
                active_nodes.push(cand)
              end
            end
          end
          candidates.clear
        end

      end # while active

      return active_nodes

    end # update_active_nodes

    def compute_ratio(start_element, end_element, line_length)
      sum = end_element.totals - start_element.totals

      # Don't include last GLUE element
      if end_element.glue?
        sum -= end_element.dimension
      end

      # JS のコードを読むと，penalty の width は，totals に入っていない．
      # しかし，compute_ration の index (end element) が penalty の場合は，
      # 計算に含まれる．
      # なぜ?

      if sum.width < line_length
        # Calculate the stretch ratio

        if sum.stretch > 0
          return (line_length - sum.width) / stretch
        else
          return Infinity
        end

      elsif sum.width > line_length
        # Calculate the shrink ratio

        if sum.shrink > 0
          return (line_length - sum.width) / shrink
        else
          return Infinity
        end
      else
        # perfect match
        return 0
      end
    end # compute_ratio

    # Add width, stretch and shrink values from the current
    # break point up to the next box or forced penalty.
    def computeSum(nodes, break_point_index)
      result = Total.new(width: @sum.width, stretch: @sum.stretch, shrink: @sum.shrink)

      for i in break_point_index .. nodes.length - 1
        if nodes[i].glue?
          result.width   += nodes[i].width
          result.stretch += nodes[i].stretch
          result.shrink  += nodes[i].shrink

        elsif nodes[i].box? || (nodes[i].penalty? && nodes[i].penalty == -Infinity && i > break_point_index)
          break
        end
      end
      return result
    end # computeSum


  end # class LineBreak

  class Tokenizer
  end
end
