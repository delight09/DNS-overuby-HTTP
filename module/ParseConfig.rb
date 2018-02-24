require 'yaml'

class ParseConfig
  attr_reader :config
  
  def initialize
    filename_prefix = File.basename($0, File.extname($0))
    filename = "#{filename_prefix}.config.yaml"
    @config = YAML.load_file(File.expand_path("../../assets/#{filename}", __FILE__))
    append_proxy
    append_api_capability
  end

  private
  def append_proxy
    http_proxy = @config['http_proxy']

    if http_proxy
      u = URI(http_proxy)
      @config['proxy_addr'] = u.host
      @config['proxy_port'] = u.port
    end
  end

  def append_api_capability
    cap = YAML.load_file(File.expand_path("../../assets/api_capability.yaml", __FILE__))
    @config['api_capability'] = cap
  end
end
