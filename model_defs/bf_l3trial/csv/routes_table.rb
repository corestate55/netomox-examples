# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# row of routes table
class RoutesTableRecord < TableRecordBase
  attr_accessor :node, :protocol, :network, :metric

  def initialize(record, debug = false)
    super(debug)

    @node = record[:node]
    @protocol = record[:protocol]
    @network = record[:network]
    @metric = record[:metric]
  end
end

# routes table
class RoutesTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, debug = false)
    super(target, 'routes.csv', debug)

    @records = @orig_table.map { |r| RoutesTableRecord.new(r, debug) }
  end

  def routes_of(node, protocol = /.+/)
    @records
      .find_all { |row| row.node == node && row.protocol =~ protocol }
      .map { |row| prefix_attr(row.network, row.metric, row.protocol) }
  end

  private

  def prefix_attr(prefix, metric, protocol)
    { prefix: prefix, metric: metric, flag: [protocol] }
  end
end
