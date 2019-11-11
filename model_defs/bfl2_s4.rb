# frozen_string_literal: true

require 'optparse'
require_relative 'bf_l2_trial/networks'

opts = ARGV.getopts('d')
if opts['d']
  puts '[batfish-L2] sample4'
  exit 0
end

puts generate_json('sample4')
