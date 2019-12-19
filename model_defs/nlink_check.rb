# frozen_string_literal: true

require 'json'
require 'netomox'
require 'optparse'

opts = ARGV.getopts('d')
if opts['d']
  puts 'Link check for nested'
  exit 0
end

nws = Netomox::DSL::Networks.new
nws.register do
  type_num = 3 # horizontal, vertical, slash/backslash
  link_num = 5
  network 'layer1' do
    node 'node11' do
      (1..link_num * type_num).each do |i|
        term_point "p#{i}"
      end
    end
    node 'node12' do
      (1..link_num * type_num).each do |i|
        term_point "p#{i}"
      end
    end
    node 'node21' do
      (1..link_num * type_num).each do |i|
        term_point "p#{i}"
      end
    end
    node 'node22' do
      (1..link_num * type_num).each do |i|
        term_point "p#{i}"
      end
    end
    # horizontal
    (1..link_num).each do |i|
      bdlink %W[node11 p#{i} node12 p#{i}]
      bdlink %W[node21 p#{i} node22 p#{i}]
    end
    # vertical
    (link_num + 1..link_num * 2).each do |i|
      bdlink %W[node11 p#{i} node21 p#{i}]
      bdlink %W[node12 p#{i} node22 p#{i}]
    end
    # slash/backslash
    (link_num * 2 + 1..link_num * 3).each do |i|
      bdlink %W[node11 p#{i} node22 p#{i}]
      bdlink %W[node12 p#{i} node21 p#{i}]
    end
  end
end

puts JSON.pretty_generate(nws.topo_data)
