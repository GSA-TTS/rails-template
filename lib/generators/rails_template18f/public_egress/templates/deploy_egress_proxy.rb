#!/usr/bin/env ruby

require "tmpdir"
require "optparse"

options = {}
parser = OptionParser.new do |opt|
  opt.on("-s", "--space SPACE", "The space apps are running in") { |o| options[:space] = o unless o == "" }
  opt.on("-a", "--apps APPLICATION", "Comma-separated list of cloud.gov apps to be proxied") { |o| options[:apps] = o unless o == "" }
  opt.on("-r", "--repo PROXY_REPOSITORY", "Address of egress proxy git repo. Default: https://github.com/GSA-TTS/cg-egress-proxy.git") { |o| options[:repo] = o unless o == "" }
  opt.on("-v", "--version PROXY_VERSION", "Git ref (sha, tag, branch) to deploy from repo. Default: main") { |o| options[:version] = o unless o == "" }
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
proxy_repo = options[:repo].nil? ? "https://github.com/GSA-TTS/cg-egress-proxy.git" : options[:repo]
proxy_version = options[:version].nil? ? "main" : options[:version]

def run(command)
  system(command) or exit $?.exitstatus
end

directory = File.dirname(__FILE__)

run "#{File.join(directory, "set_space_egress.sh")} -s #{options[:space]} -t"
run "#{File.join(directory, "set_space_egress.sh")} -s #{options[:space]}-egress -p"

Dir.mktmpdir do |dir|
  run "git clone #{proxy_repo} #{dir}"
  run "cd #{dir}; git checkout #{proxy_version}"
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
  run "cd #{dir}; bin/cf-deployproxy -a #{options[:apps]} -p ep -e egress_proxy"
end
