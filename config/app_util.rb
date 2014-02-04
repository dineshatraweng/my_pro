class AppUtil
  
  def self.windows?
    return @windows if defined?(@windows)
    @windows = if (RUBY_PLATFORM =~ /java/i)
      require "java"
      java_import java.lang.System
      (System.getProperty("os.name") =~ /windows/i)
    else
      (RUBY_PLATFORM =~ /mswin|win32|mingw|bccwin|cygwin/)
    end        
  end
    
  def self.load_app_config
    return true if defined?(APP_CONFIG)   
    require 'active_support'
    cfg = YAML.load_erb(File.join(Rails.root, "config", "app_config.yml"))
    env_cfg = cfg[Rails.env]
    inherit = {}
    (env_cfg[:inherit] || "").split(",").each do |name|
      c = cfg[name]
      inherit.deep_merge!(c) if c.is_a?(Hash)  
    end
    Object.const_set("APP_CONFIG", HashWithIndifferentAccess.new(inherit.deep_merge(env_cfg)))
    # define the default values here
#    Object.const_set("APP_CONFIG_DEFAULTS", app_config_defaults)
  end
  
  # The default configuration is read from a separate file. In order facilitate this we
  # read the file and then create the method
#instance_eval(%Q(
#  def app_config_defaults
#    #{IO.read(File.join(File.dirname(__FILE__), 'app_config_defaults.rb'))}
#  end
#  )
#) unless respond_to?(:app_config_defaults)
#
end

# monkey patch the YAML module 
module YAML
  def YAML.include file_name
      require 'erb'
      ERB.new(IO.read(file_name)).result
  end

  def YAML.load_erb file_name, quote_enclose=false
    c = YAML::load(YAML::include(file_name))      
    f = lambda do |input, output|
      input.each do |k, v|
          v = input.is_a?(Hash) ? v : k
          r = v.is_a?(Hash) ? f.call(v, HashWithIndifferentAccess.new) :
                        v.is_a?(Array) ? f.call(v, []) :
                        quote_enclose ? "\"#{v}\"" : v
          input.is_a?(Hash) ? (output[k]=r) : (output<<r)                        
      end
      output
    end
    f.call(c, HashWithIndifferentAccess.new)
  end
end

# monkey patch the Object class
class Object
  def app_config *args
    options = args.extract_options!
    default = options.has_key?(:default) ? options[:default] : ""
    ret = APP_CONFIG
    args.each do |arg|
      ret = (ret[arg] rescue return default)
    end
    ret.nil? ? default : ret
  end

  def host_port
    [app_config(:app, :host),app_config(:app, :port).blank? ? nil : app_config(:app, :port)].compact.join(':')
  end
end   
