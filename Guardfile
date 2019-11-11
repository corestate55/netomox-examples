# frozen_string_literal: true

# Usage memo:
# In guard pry shell,
# ```
# [1] guard(main)> change model_defs/path/to/watched_file
# ```
# `change` command makes file-change event.
# default (empty-return) is `all` : makes change event for all watched-files.
# see `help`.

require 'optparse'

# Use -g to specify target_file instead of guard -g (group).
opts = ARGV.getopts('g:')
target_file = opts['g']
base_name = File.basename(target_file, '.rb')
command_str = "bundle exec rake TARGET=#{target_file}"
dir_name = base_name =~ /bfl2_s\d/ ? 'bf_l2_trial' : base_name # exception rule

puts "# top_file: #{target_file}"
puts "# base_name: #{base_name}"
puts "# command: #{command_str}"

target = "model_defs/#{base_name}.rb"
layout = "model_defs/layout/#{base_name}-layout.json"
subs = "model_defs/#{dir_name}/.*.rb"

guard :shell do
  watch Regexp.new("(?:#{target}|#{layout}|#{subs})") do |watched_file|
    puts "# changed file: #{watched_file[0]}"
    puts "# exec: #{command_str}"
    `#{command_str}`
  end
end
