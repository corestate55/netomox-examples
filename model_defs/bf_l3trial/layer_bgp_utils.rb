# frozen_string_literal: true

# term-point name counter for bgp-proc topology
class TPNameCounter
  attr_accessor :lo, :ebgp, :max_neighbors

  def initialize(debug = false)
    @use_debug = debug

    @lo = -1 # count neighbors connected from loopback (iBGP)
    @ebgp = -1 # count neighbors connected from other interface (eBGP)
    @max_neighbors = -99 # dummy, use #init_name_count for each term_point
  end

  # rubocop:disable Metrics/MethodLength
  def make_tp_name(term_points, term_point)
    init_max_name_count(term_points, term_point)

    debug '#### make_tp_name, tp: ', term_point
    debug '#### make_tp_name, cnt: ', counters
    if loopback?(term_point)
      loopback_tp_name(term_point)
    elsif last_multiple_ebgp?
      last_multiple_ebgp_name(term_point)
    elsif under_multiple_ebgp?
      under_multiple_ebgp_name(term_point)
    else
      single_ebgp_name(term_point)
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def init_max_name_count(term_points, term_point)
    @max_neighbors = neighbors_owned_tp(term_points, term_point)
  end

  # debug print
  def debug(*message)
    puts message if @use_debug
  end

  def counters
    { lo: @lo, ebgp: @ebgp, max_neighbors: @max_neighbors }
  end

  def neighbors_owned_tp(term_points, term_point)
    term_points
      .map { |tp| tp.interface == term_point.interface }
      .count { |value| value == true }
  end

  def select_tp_name(count, name)
    count.positive? ? "#{name}:#{count}" : name
  end

  def loopback?(term_point)
    term_point.interface =~ /(Loopback|lo)/i
  end

  def last_multiple_ebgp?
    @ebgp + 2 == @max_neighbors && @ebgp != -1
  end

  def under_multiple_ebgp?
    @max_neighbors > 1 && @ebgp + 1 < @max_neighbors
  end

  def loopback_tp_name(term_point)
    # NOTICE: Loopback address is used multiple
    # in bgp-proc neighbors (iBGP bgp-proc edges).
    @lo += 1
    debug '##### (A): cnt: ', counters
    select_tp_name(@lo, term_point.ip)
  end

  def last_multiple_ebgp_name(term_point)
    @ebgp += 1 # reset counter
    debug '##### (B): cnt: ', counters
    select_tp_name(@max_neighbors - 1, term_point.ip)
  end

  def under_multiple_ebgp_name(term_point)
    @ebgp += 1 # counting
    debug '##### (C): cnt: ', counters
    select_tp_name(@ebgp, term_point.ip)
  end

  def single_ebgp_name(term_point)
    debug '##### (D): cnt: ', counters
    term_point.ip
  end
end
