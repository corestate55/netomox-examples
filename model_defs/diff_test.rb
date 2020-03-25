# frozen_string_literal: true

require 'optparse'

opts = ARGV.getopts('d')
if opts['d']
  puts 'diff viewer test data'
  exit 0
end

defs_dir = './model_defs'
tests_dir = "#{defs_dir}/model_diff_test"
data_dir = "#{defs_dir}/model"

system "mkdir -p #{data_dir}"
system "bundle exec ruby #{tests_dir}/multiple.rb"
Tempfile.create(basename: 'diff_test', tmpdir: '/tmp') do |tmpfile|
  file1 = "#{data_dir}/test_multiple1.json"
  file2 = "#{data_dir}/test_multiple2.json"
  system "bundle exec netomox diff -o #{tmpfile.path} #{file1} #{file2}"
  system "cat #{tmpfile.path}"
end
