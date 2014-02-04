module ActionController

  class Request

    alias_method :etag_matches_original?, :etag_matches?

    def etag_matches?(etag)
      begin
      !env['HTTP_USER_AGENT'].include?('MSIE') && etag_matches_original?(etag)
      rescue
      return false
      end
    end

  end

  class Response

    alias_method :etag_original?, :etag?

    def etag?
      begin
      request.env['HTTP_USER_AGENT'].include?('MSIE') || etag_original?
      rescue
      return true
      end
    end


  end
end