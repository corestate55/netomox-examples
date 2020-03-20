# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# OSPF-Areas in BGP-AS table (for bgp-as topology)
class AreasInASTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    @records = table_of[:nodes_in_as].make_areas_in_as
  end
end
