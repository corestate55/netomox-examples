# frozen_string_literal: true

require 'forwardable'
require_relative 'table_base'

# Links inter BGP-AS table (for bgp-as topology)
class LinksInterASTable < TableBase
  extend Forwardable

  def_delegators :@records, :each, :find, :[]

  def initialize(target, table_of, debug = false)
    super(target, nil, debug)

    @records = table_of[:edges_bgp].make_links_inter_as
  end

  def interfaces_inter_as(asn)
    @records
      .find_all { |link| link[:source][:as] == asn }
      .map { |link| link[:source] }
  end
end
