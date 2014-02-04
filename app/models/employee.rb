class Employee
  attr_accessor :mail, :cn, :user

  def initialize(hash)
    if hash.is_a?(Hash)
      self.mail = hash[:mail]
      self.cn = hash[:cn]
      self.user = hash[:user]
    elsif hash.is_a?(String)

    end
  end
  
end