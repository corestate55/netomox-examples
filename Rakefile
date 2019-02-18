require 'rake/clean'

YANG_DIR = './yang'.freeze
MODEL_DIR = './model'.freeze
MODEL_DEF_DIR = './model_defs'.freeze
YANG = %W[
  #{YANG_DIR}/ietf-l2-topology@2018-06-29.yang
  #{YANG_DIR}/ietf-l3-unicast-topology@2018-02-26.yang
  #{YANG_DIR}/ietf-network-topology@2018-02-26.yang
  #{YANG_DIR}/ietf-network@2018-02-26.yang
].freeze
JSON_SCHEMA = "#{MODEL_DIR}/topol23.jsonschema".freeze
JTOX = "#{MODEL_DIR}/topol23.jtox".freeze
TARGET_RB = FileList["#{MODEL_DEF_DIR}/target*.rb"]
TARGET_JSON = FileList.new do |f|
  f.include("#{MODEL_DIR}/target*.json")
  f.exclude("#{MODEL_DIR}/*.orig.json")
end

task default: %i[rb2json model_check validate_json json2xml]

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
    sh "bundle exec netomox check #{json}"
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

CLOBBER.include(
  TARGET_JSON, # JTOX, JSON_SCHEMA,
  "#{MODEL_DIR}/*.xml",
  "#{MODEL_DIR}/test_*.json",
)
CLEAN.include('**/*~')
