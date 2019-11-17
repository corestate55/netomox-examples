# frozen_string_literal: true

require 'optparse'
require_relative 'bf_l2trial/networks_p'

opts = ARGV.getopts('d')
if opts['d']
  puts '[batfish-L2] sample3'
  exit 0
end

puts generate_json('sample3')