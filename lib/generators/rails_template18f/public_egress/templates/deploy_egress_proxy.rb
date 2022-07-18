#!/usr/bin/env ruby

require "tmpdir"
require "optparse"

options = {}
parser = OptionParser.new do |opt|
  opt.on("-s", "--space SPACE", "The space apps are running in") { |o| options[:space] = o }
  opt.on("-a", "--apps APPLICATION", "Comma-separated list of cloud.gov apps to be proxied") { |o| options[:apps] = o }
end
parser.parse!

if options[:space].nil?
  warn "--space is a required argument"
  puts parser
  exit 1
end
if options[:apps].nil?
  warn "--apps is a required argument"
  puts parser
  exit 1
end

def run(command)
  system(command) or exit $?.exitstatus
end

directory = File.dirname(__FILE__)

run "#{File.join(directory, "set_space_egress.sh")} -s #{options[:space]}-egress -p"

Dir.mktmpdir do |dir|
  run "git clone https://github.com/GSA/cg-egress-proxy.git #{dir}"
  config_dir = File.join(directory, "../../config/deployment/egress_proxy")
  options[:apps].split(",").each do |app|
    begin
      FileUtils.cp File.join(config_dir, "#{app}.allow.acl"), dir
    rescue
      warn "config/deployment/egress_proxy/#{app}.allow.acl did not exist. Please create it if you need to customize the app's allow rules"
    end
    begin
      FileUtils.cp File.join(config_dir, "#{app}.deny.acl"), dir
    rescue
      warn "config/deployment/egress_proxy/#{app}.deny.acl did not exist. Please create it if you need to customize the app's deny rules"
    end
  end
  run "cd #{dir}; make; bin/cf-deployproxy #{options[:apps]}"
end
