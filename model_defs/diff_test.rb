require 'optparse'

opts = ARGV.getopts('d')
if opts['d']
  puts 'diff viewer test data'
  exit 0
end

defs_dir = './model_defs'
tests_dir = "#{defs_dir}/model_diff_test"
data_dir = "#{defs_dir}/model"

system "bundle exec ruby #{tests_dir}/multiple.rb"
Tempfile.create(basename: 'diff_test', tmpdir: '/tmp') do |tf|
  system "bundle exec netomox diff -o #{tf.path} #{data_dir}/test_multiple1.json #{data_dir}/test_multiple2.json"
  system "cat #{tf.path}"
end
