require 'uri'
require 'active_support'
require 'rest_client'

module GSA

  class NoInternetConnectionError < Exception; end
  def self.default_options
    @default_options ||= { 	:gsa_url => "",
							:search_term => "",
							:coutput => "json",
							:access => "p",
							:client => "default_frontend",
							:proxystylesheet => "default_frontend",
							:site => "default_collection",
              :start => 0,
              :num => 10
						}
  end

  def self.search(args = {})
	default_options
    @default_options.merge!(args)
	raise ArgumentError, "GSA URL missing. Please provide valid arguments." if @default_options[:gsa_url].empty?
	return perform_search
  end

  protected
    def self.perform_search
		json_response = RestClient.post(search_url,{},:content_type => "", :response => "json")
    response_object = ActiveSupport::JSON.decode(json_response)
    response_object['next_start'] = @default_options[:start] + @default_options[:num]
    response_object['number'] = @default_options[:num]
		return response_object.blank? ? {} : response_object
	end

	def self.search_url
		url = URI.escape("#{@default_options[:gsa_url]}cluster?q=#{@default_options[:search_term]}&coutput=#{@default_options[:coutput]}&" +
          "access=#{@default_options[:access]}&output=xml_no_dtd&client=#{@default_options[:client]}&proxystylesheet=#{@default_options[:proxystylesheet]}&" +
          "site=#{@default_options[:site]}&start=#{@default_options[:start]}&num=#{@default_options[:num]}"
    )
		return url
	end
end