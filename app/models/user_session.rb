class UserSession < Authlogic::Session::Base
  allow_http_basic_auth false
  logout_on_timeout true
  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end

  def persisted?
    false
  end

  def generic_error
    clear = false
    errors.each do |attr,message|
        clear = true if (attr.to_s == "username" or attr.to_s == "password")
      end

    if clear
      errors.clear
      errors.add_to_base("Invalid login credentials")
    end
  end
end
