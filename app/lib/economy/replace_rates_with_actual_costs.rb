module Economy
  # Handles a special case when rates should not be calulated but actual costs should instead.
  # Affects both rate and cost calulations
  #
  # If the refugee has placements with a legal_code that has the attribute
  #   #exempt_from_rate set to true, then
  # 1. The periods for those placements must not be calulated for rates.
  # 2. All the actual costs for the refugee within those periods must be included instead
  class ReplaceRatesWithActualCosts < Base
    def initialize(refugee, options = {})
      @refugee = refugee
      @interval = { from: options[:from], to: (options[:to] || Date.today) }

      # Date interval for the exception from exempt rule
      @exception_from_exempt = options[:exception_interval]

      @intervals_with_exempt = intervals_with_exempt
    end

    # See doc at #as_array
    def sum
      as_array.map do |x|
        next x if x.is_a? BigDecimal

        next x[:days] * x[:amount] if days_hash?(x)
        next x[:months] * x[:costs] if months_hash?(x)
        next x[:months] * (x[:fee] + x[:po_cost] + x[:expense]) if po_cost_hash?(x)
      end.compact.sum
    end

    # See doc at #as_array
    def as_formula
      as_array.map do |x|
        next x.to_s if x.is_a? BigDecimal
        next if x[:days]&.zero? || x[:months]&.zero?

        next "#{x[:days]}*#{x[:amount]}" if days_hash?(x)
        next "#{x[:months]}*#{x[:costs]}" if months_hash?(x)
        next "#{x[:months]}*(#{x[:fee]}+#{x[:po_cost]}+#{x[:expense]})" if po_cost_hash?(x)
      end.compact.join('+')
    end

    # Returns an array. Each element can be of one of those three forms
    # { days: Integer, amount: Float }
    # { months: Float, costs: Float }
    # Float
    def as_array
      return [] if @intervals_with_exempt.empty?

      @intervals_with_exempt.map do |interval_with_exempt|
        ::Economy::PlacementAndHomeCost.new(@refugee.placements, interval_with_exempt).as_array +
          ::Economy::ExtraContributionCost.new(@refugee, interval_with_exempt).as_array +
          ::Economy::RefugeeExtraCost.new(@refugee, interval_with_exempt).as_array +
          ::Economy::PlacementExtraCost.new(@refugee.placements, interval_with_exempt).as_array +
          ::Economy::FamilyAndEmergencyHomeCost.new(@refugee.placements, interval_with_exempt).as_array
      end.flatten.compact
    end

    # Returns an array of days that has exempt_from_rate
    def exempt_days_array
      # Create a range of dates in the exempt_from_rate periods and convert it to an array
      @intervals_with_exempt.map do |period|
        (period[:from].to_date..period[:to].to_date).to_a
      end.flatten
    end

    private

    # Selects the refugees placements that has a legal_code with #exempt_from_rate set to true
    # Returns and array of hashes with date intervals for those periods
    def intervals_with_exempt
      placement_intervals = @refugee.placements.map do |placement|
        next unless placement.legal_code.exempt_from_rate?

        from = latest_date(placement.moved_in_at, @interval[:from])
        to = earliest_date(@refugee.citizenship_at, placement.moved_out_at, @interval[:to])

        next unless from && to
        next { from: from, to: to } unless @exception_from_exempt

        reduce_interval(from, to)
      end.flatten.compact

      remove_overlaps_in_date_intervals(placement_intervals)
    end

    def reduce_interval(from, to)
      return { from: from, to: to } unless @exception_from_exempt[:from] && @exception_from_exempt[:to]

      if within_exception_interval?(from) && within_exception_interval?(to)
        return [
          { from: from, to: @exception_from_exempt[:from] - 1.day },
          { from: @exception_from_exempt[:to] + 1.day, to: to }
        ]
      end

      if within_exception_interval?(from)
        from = @exception_from_exempt[:to] + 1.day
      elsif within_exception_interval?(to)
        to = @exception_from_exempt[:from] - 1.day
      end

      { from: from, to: to }
    end

    def within_exception_interval?(date)
      date >= @exception_from_exempt[:from] && date <= @exception_from_exempt[:to]
    end
  end
end
