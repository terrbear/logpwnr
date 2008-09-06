require 'net/ssh'
require 'net/scp'

class App < ActiveRecord::Base
  #name, summary, last_harvested, timestamps
  has_many :locations
  
  validates_presence_of :name, :summary  
  
  def csv_file
    self.name.downcase
  end
  
  def harvest!
    `rm -f *.log *.log.gz *.csv`
    self.locations.each do |loc|
      loc.zip_logs
      loc.download_logs
    end
    `cat *.log > #{self.name}.log`
    `ruby script/logpwnr.rb #{self.name}.log > public/files/#{self.name.downcase}.csv`
  end
end
