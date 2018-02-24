require 'net/http'
require 'json'

class ResolvOverHTTP
  def initialize(api='google-public-dns', proxy_addr=nil, proxy_port=nil)
    @api = api
    @proxy_addr = proxy_addr
    @proxy_port = proxy_port
  end

  def connection_valid?()
    case @api
    when 'google-public-dns'
      uri = URI('https://dns.google.com/generate_204')
      res = fetch_uri_https(uri)

      if res.code == '204'
        return true
      else
        return false
      end
    else
      raise "\nAPI:#{@api} is not valid, exiting..." # Catch all API typo error
    end
  end

  def query(name, type='A')
    uri = build_uri(name, type)
    res = fetch_uri_https(uri)

    parse_response_rt_arr(res.body)
  end

  private
  def fetch_uri_https(uri)
    Net::HTTP.start(uri.host, uri.port, @proxy_addr, @proxy_port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri

      return http.request request
    end
  end

  def build_uri(name, type)
    case @api
    when 'google-public-dns'
      return URI("https://dns.google.com/resolve?name=#{name}&type=#{type}&edns_client_subnet=0.0.0.0/0")
    end
  end

  def parse_response_rt_arr(resp_body)
    case @api
    when 'google-public-dns'
      json_resp = JSON.parse(resp_body)
      if json_resp['Status'] == 0
        if json_resp.has_key?('Answer')
          arr = Array.new

          json_resp['Answer'].each do |e|
            arr.push(e['data'])
          end
          return arr
        end
      end  
      # blah
    end
  end
end
