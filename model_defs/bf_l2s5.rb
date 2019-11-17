# frozen_string_literal: true

require 'optparse'
require_relative 'bf_l2trial/networks_p'

opts = ARGV.getopts('d', 'debug:')
if opts['d']
  puts '[batfish-L2] sample5'
  exit 0
end

if opts['debug']
  dump('sample5', opts['debug'])
  exit 0
end

puts generate_json('sample5')
