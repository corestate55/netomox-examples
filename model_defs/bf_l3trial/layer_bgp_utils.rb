# frozen_string_literal: true

# term-point name counter for bgp-proc topology
class TPNameCounter
  attr_accessor :lo, :ebgp, :max_neighbors

  def initialize(term_points)
    init_tp_name_table(term_points)
  end

  # term_point: BGPProcEdge
  def tp_name(term_point)
    @count_of_tp[term_point.ip] += 1
    select_tp_name(term_point)
  end

  private

  # term_points: Array of BGPProcEdge
  def init_tp_name_table(term_points)
    @count_of_tp = {}
    term_points.each do |term_point|
      @count_of_tp[term_point.ip] = -1 # use ip as counter key
    end
  end

  def select_tp_name(term_point)
    count = @count_of_tp[term_point.ip]
    name = term_point.ip
    count.positive? ? "#{name}:#{count}" : name
  end
end
