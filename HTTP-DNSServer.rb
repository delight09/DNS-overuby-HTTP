#!/usr/bin/env ruby
# TODO description

require 'async/dns'
require 'async/dns/system'

require_relative 'module/ResolvOverHTTP'
require_relative 'module/ParseConfig'

class TrustedServer < Async::DNS::Server
  def process(name, resource_class, transaction)
    abbr_resource_class = to_abbr(resource_class)
    if $config['api_capability'][$config['api']].include? abbr_resource_class
      resp_hosts = $hosts.lookup(name)
      if resp_hosts
        transaction.respond!(resp_hosts)
      else
        resp_rshttp = $rs.query(name, abbr_resource_class)

        if resp_rshttp
          resp_rshttp.each do |v|
            transaction.respond!(v)
          end
        else
          transaction.fail!(:NXDomain)
        end
      end
    else
      transaction.fail!(:ServFail)
    end
  end
  
  private
  def to_abbr(resource_class)
    return resource_class.to_s.match(/IN::(\S*)$/)[1]
  end
end

# Read config
myconfig = ParseConfig.new
$config = myconfig.config

# Init resolvers
$rs = ResolvOverHTTP.new($config['api'], $config['proxy_addr'], $config['proxy_port'])
if not $rs.connection_valid?
  raise "\nUnable establish connection with DNS-over-HTTP server(API choosen: google-public-dns)
         \nServer startup failure!!"
end
puts "INFO: Connection with remote DNS-over-HTTP server verified"

$hosts = Async::DNS::System::Hosts.new
File.open(File.expand_path("../assets/external_hosts.txt", __FILE__)) do |file|
  $hosts.parse_hosts(file)
end
puts "INFO: File external_hosts.txt parsed successful"

# Run server
server = TrustedServer.new([[:udp, $config['listen_address'], $config['listen_port']]])
server.run
