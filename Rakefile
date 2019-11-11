# frozen_string_literal: true

# Usage:
#   `bundle exec rake [TARGET=./model_defs/hoge.rb]`
# Use `TARGET` env-var to specify a target model-def script.
# without `TARGET`, run tasks for all scripts in `model_defs` directory.

require 'rake'
require 'rake/clean'
require 'json'

YANG_DIR = './yang'
MODEL_DIR = './netoviz/static/model'
MODEL_DEF_DIR = './model_defs'
MODEL_LAYOUT_DIR = "#{MODEL_DEF_DIR}/layout"
YANG = %W[
  #{YANG_DIR}/ietf-l2-topology@2018-06-29.yang
  #{YANG_DIR}/ietf-l3-unicast-topology@2018-02-26.yang
  #{YANG_DIR}/ietf-network-topology@2018-02-26.yang
  #{YANG_DIR}/ietf-network@2018-02-26.yang
].freeze
JSON_SCHEMA = "#{YANG_DIR}/topol23.jsonschema"
JTOX = "#{YANG_DIR}/topol23.jtox"
TARGET_RB = if ENV['TARGET'].nil?
              FileList["#{MODEL_DEF_DIR}/*.rb"]
            else
              [ENV['TARGET']]
            end
TARGET_JSON = TARGET_RB.map do |rb|
  "#{MODEL_DIR}/#{File.basename(rb).ext('json')}"
end

task default: %i[rb2json model_check validate_json json2xml install_layout]

desc 'make json schema file from yang'
task :jsonschema do
  puts "# check json_schema:#{JSON_SCHEMA}"
  file JSON_SCHEMA do
    puts "## make json_schema:#{JSON_SCHEMA}"
    sh "pyang -f json_schema -o #{JSON_SCHEMA} #{YANG.reverse.join(' ')}"
  end
end

desc 'make jtox (json-to-xml) schema file from yang'
task :jtox do
  puts "# check jtox:#{JTOX}"
  file JTOX do
    puts "## make jtox:#{JTOX}"
    sh "pyang -f jtox -o #{JTOX} #{YANG.join(' ')}"
  end
end

desc 'make json topology data from DSL definition'
task :rb2json do
  puts '# check rb2json'
  TARGET_RB.each do |rb|
    json = "#{MODEL_DIR}/#{File.basename(rb.ext('json'))}"
    puts "## make json:#{json}"
    sh "bundle exec ruby #{rb} > #{json}"
  end
end

desc 'check topology data consistency'
task :model_check do
  puts '# check model consistency'
  TARGET_JSON.each do |json|
    puts "# check model json:#{json}"
    filter = 'jq \'.[].messages[] | select(.severity=="error")\''
    sh "bundle exec netomox check #{json} | #{filter}"
  end
end

desc 'validate json topology data by its json schema'
task validate_json: %i[jsonschema] do
  puts '# validate json with jsonschema'
  TARGET_JSON.each do |json|
    puts "## validate json:#{json}"
    sh "jsonlint-cli -s #{JSON_SCHEMA} #{json}"
  end
end

desc 'make xml topology data from json data'
task json2xml: %i[jtox] do
  puts '# check json2xml'
  TARGET_JSON.each do |json|
    xml = json.ext('xml')
    puts "## make xml:#{xml}"
    if File.basename(json) == 'diff_test.json'
      puts '### skip (it include diff-state)'
      next
    end
    sh "json2xml #{JTOX} #{json} | xmllint --output #{xml} --format -"
  end
end

desc 'validate xml topology data by its xml schema'
task :validate_xml do
  puts 'NOT yet.'
  # yang2dsdl -x -j -t config -d #{MODEL_DIR} -v #{xml} #{YANG}
end

TEST_DEF_RB = FileList["#{MODEL_DEF_DIR}/test_*.rb"]
desc 'make diff-viewer test data from test data defs'
task :testgen do
  TEST_DEF_RB.each do |rb|
    sh "bundle exec ruby #{rb}"
  end
end

desc 'install layout file'
task :install_layout do
  puts '# install layout file'
  TARGET_JSON.each do |json|
    to_dir = File.dirname(json)
    base = File.basename(json).ext('')
    layout_json = "#{MODEL_LAYOUT_DIR}/#{base}-layout.json"
    sh "cp #{layout_json} #{to_dir}" if File.exist?(layout_json)
  end
end

desc 'make index file'
task :make_index do
  descrs = TARGET_RB.to_ary.map do |rb|
    {
      file: File.basename(rb).ext('json'),
      label: `bundle exec ruby #{rb} -d`.chomp!
    }
  end
  File.open("#{MODEL_DIR}/_index.json", 'w') do |f|
    f.write(JSON.pretty_generate(descrs))
  end
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    warn 'RuboCop is disabled'
  end
end

CLOBBER.include(
  TARGET_JSON, # JTOX, JSON_SCHEMA,
  "#{MODEL_DIR}/*.xml",
  "#{MODEL_DIR}/test_*.json"
)
CLEAN.include('**/*~')
