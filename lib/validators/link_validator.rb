class LinkValidator < ActiveModel::Validator

  def validate(record)
    if record.doctype == Document::DOCTYPE[:url]
      # validate link with URI.parse
      unless UrlExistsValidator.validate_with_uri(record.link.strip)
        record.errors[:link] << (options[:message] || 'is not a valid URL')
      end
      # validate link is accessible
      #unless UrlExistsValidator.exists(record.link.strip)
      #  record.errors[:link] << (options[:message] || 'is not an accessible URL')
      #end
    end
  end


end

class UrlExistsValidator

  require 'rest_client'
  require 'uri'

  def validate_with_uri(url)
    begin
      parsed_url =  URI.parse(url)
      Rails.logger.info("URL : #{url} is validated with URI.parse}")
      return true
    rescue => e
      Rails.logger.info("URL : #{url} is NOT validated with URI.parse}")
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      return false
    end

  end
  def self.exists(url)
    return false if url.blank?
    validate_url_exists(url)
  end

  def self.validate_url_exists(url)
    code = get_resp_code(url)
    return [200].include?(code)
  end

  def self.get_resp_code(url)
    code = 000
    begin
      response = RestClient.head url
      code = response.code
      Rails.logger.info "URL => #{url}"
      Rails.logger.info "RESPONSE code => #{code}"
    rescue SocketError => error
      code = 000
      Rails.logger.info(error.message)
      Rails.logger.info("URL '#{url}' gives SocketError,  status 000")
    rescue RestClient::ResourceNotFound => error
      code = 404
      Rails.logger.info(error.message)
      Rails.logger.info("URL '#{url}' gives ResourceNotFound Error, status 404 ")
    end
    return code
  end
end