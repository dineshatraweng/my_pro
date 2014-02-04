# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
#if Rails.env.newprod?
#user = User.find_by_username("tibcoadmin")
#user.update_attributes(:password => "n3wpr0d",:password_confirmation => "n3wpr0d")
#end
#Group.all.each {|g| g.update_attributes(:ancestry => nil) if g.ancestry==""}
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
#if Rails.env.staging?
# user = User.find_by_username('tibcoadmin')
# user.update_attributes(:username => 'rawadmin',:password => 'raw123',:password_confirmation => 'raw123')
#end
#Group.all.each {|g| g.update_attributes(:ancestry => nil) if g.ancestry==""}                        Product
#puts Rails.env
#
#  user = User.find_by_username("tibcoadmin")
#  user.update_attributes(:password => "raw123",:password_confirmation => "raw123", :username => 'rawadmin')
#end
@users =[
    #{:username => "ganesh", :email => "gakulkar@tibco.com", :firstname => "Ganesh", :lastname=>"Kulkarni", :password => "2a6363"},
    #{:username => "priyadarshini", :email => "prchandr@tibco.com", :firstname => "Priyadarshini", :lastname=>" Chandra", :password => "3614d9"}
{:username => "priya", :email => "pprasad@tibco.com", :firstname => "Priya", :lastname=>"Prasad", :password => "27bc3368"}
]

if Rails.env.development?
  #User.create(:username=>"rawadmin",:email=>"rubyonrails.work@gmail.com",:password => "raw123",:password_confirmation => "raw123")
  unless @users.blank?
    @users.each do |user|
      User.create(:username => user[:username], :email => user[:email], :firstname => user[:firstname], :lastname => user[:lastname], :password => user[:password], :password_confirmation => user[:password])
    end
  end
end

if Rails.env.staging?
  #user = User.find_by_username("tibcoadmin")
  #user.update_attributes(:password => "t1bc0r0cks",:password_confirmation => "t1bc0r0cks")
  unless @users.blank?
    @users.each do |user|
      User.create(:username => user[:username], :email => user[:email], :firstname => user[:firstname], :lastname => user[:lastname], :password => user[:password], :password_confirmation => user[:password])
    end
  end
end


if Rails.env.production?
  #user = User.find_by_username("tibcoadmin")
  #user.update_attributes(:password => "t1bc0r0cks",:password_confirmation => "t1bc0r0cks")
  unless @users.blank?
    @users.each do |user|
      User.create(:username => user[:username], :email => user[:email], :firstname => user[:firstname], :lastname => user[:lastname], :password => user[:password], :password_confirmation => user[:password])
    end
  end
end

