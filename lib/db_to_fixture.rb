
module TibcomunityDB
  require "active_record"
  DIR_PATH= "#{Rails.root}/public/jive_db"
  db = ActiveRecord::Base.establish_connection(
      :adapter  => "mysql2",
      :host     => "localhost",
      :username => "root",
      :password => "root",
      :database => "tibcommunity"
  )

  class Jivedomain < ActiveRecord::Base
    self.table_name="jivedomain"

    def self.dump_to_yaml
      file_path = DIR_PATH + "/jivedomain.yml"
      File.open(file_path, 'w') do |f|
        self.all.each do |m|
          f.write(m.attributes.to_yaml)
        end
      end
    end
  end

  class JiveDomainGroup < ActiveRecord::Base
    self.table_name="jivedomaingroup"
    def self.dump_to_yaml
      file_path = DIR_PATH + "/jive_domain_group.yml"
      File.open(file_path, 'w') do |f|
        self.all.each do |m|
          f.write(m.attributes.to_yaml)
        end
      end
    end

  end
  class Group < ActiveRecord::Base
    self.table_name="jivegroup"
    def self.dump_to_yaml
      file_path = DIR_PATH + "/jivegroup.yml"
      File.open(file_path, 'w') do |f|
        self.all.each do |m|
          f.write(m.attributes.to_yaml)
        end
      end
    end
  end

end