require 'net/ldap'

class LDAPConnector
  def self.connect(username,password)
    if username.blank? || password.blank?
      return {:error => "Username or Password Missing."}
    else
      values = {}
      auth = {:method => :simple, :username => app_config(:ldap,:username), :password => app_config(:ldap,:password)}
      ldap = Net::LDAP.new(:host => app_config(:ldap,:host), :port => app_config(:ldap,:port), :auth => auth, :encryption => :simple_tls)
      begin
        if ldap.bind
          treebase = app_config(:ldap,:search_base)
          filter = Net::LDAP::Filter.eq("sAMAccountName", username)
          attrs = ["mail","cn"]

          ldap.search(:base => treebase, :filter => filter, :attributes => attrs,:return_result => false) do |entry|
            values[:user] = entry.dn
            entry.each do |attr, val|
              values[:"#{attr}"] = val
            end
          end
          ldap.auth values[:user],password
          begin
            return values if ldap.bind
          rescue
            return {:error => "Username or Password is invalid."}
          end
        end
      rescue
        return {:error => "Something went wrong. Please try again Later."}
      end
    end
  end
end

#LDAPConnector.connect("172.16.0.53","rohits","raw123")