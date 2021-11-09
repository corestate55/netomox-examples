# frozen_string_literal: true

require 'optparse'
require_relative 'mddo_trial/networks'

opts = ARGV.getopts('d', 'debug:')
if opts['d']
  puts 'MDDO Trial'
  exit 0
end

if opts['debug']
  dump('sample3', opts['debug'])
  exit 0
end

puts generate_json('sample3')
