task :UserGroup => :environment  do
  require 'yaml'
  documents = YAML.load_stream(open("#{Rails.root}/config/initializers/Jive_db/jivegroup.yml"))
  documents.each do |p|
      group = UserGroup.new
      group.id = p['groupID']
      group.name = p['name']
      group.description =  p['description']
      group.save
      puts "*****************************************************************************"
      puts group.inspect
  end
end


task :UserDomain => :environment  do
  require 'yaml'
  documents = YAML.load_stream(open("#{Rails.root}/config/initializers/Jive_db/jivedomain.yml"))
  documents.each do |p|
      domain = UserDomain.new
      domain.id = p['domainID']
      domain.name = p['name']
      domain.save
    puts "********************************************************************************************"
    puts domain.inspect
  end
end


task :UserDomainGroup => :environment  do
  require 'yaml'
  documents = YAML.load_stream(open("#{Rails.root}/config/initializers/Jive_db/jive_domain_group.yml"))
  documents.each do |p|
    ud = UserDomainGroup.create(:user_group_id => p['groupID'] , :user_domain_id => p['domainID'])
    puts "**************************************************************************************"
    puts ud.inspect
  end
end

task :clear_user_domain_data => :environment do
  puts "Deleting all UserDomainGroup data........."
  UserDomainGroup.delete_all
  puts ".......................................done "
  puts "Deleting all UserDomain data........."
  UserDomain.delete_all
  puts ".......................................done "
  puts "Deleting all UserGroup data........."
  UserGroup.delete_all
  puts ".......................................done "
end
