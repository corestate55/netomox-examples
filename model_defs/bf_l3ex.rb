# frozen_string_literal: true

require 'optparse'
require_relative 'bf_l3trial/networks'

# usage:
#   bundle exec ruby THIS.rb --debug=[bgp_as|bgp_proc|ospf_area|ospf_proc|l3]
# with bundle exec, ARGV[0] is not THIS script name.

opts = ARGV.getopts('d', 'debug:')
if opts['d']
  puts 'batfish trial (L3 example)'
  exit 0
end

debug = opts['debug'] ? opts['debug'].intern : nil
csv_dir = 'model_defs/bf_l3trial/csv/example'
bf_nws = BFL3Networks.new(target: 'example', debug: debug, csv_dir: csv_dir)

if debug
  bf_nws.debug_print
else
  puts bf_nws.integrate
end
