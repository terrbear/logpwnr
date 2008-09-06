class Location < ActiveRecord::Base
  #ip, directory, user
  
  belongs_to :app
  
  validates_presence_of :ip, :directory, :user
  
  def zip_logs
    Net::SSH.start(self.ip, self.user) do |ssh|
      ssh.exec!('rm -f ~/*.log ~/*.log.gz') || ""
      ssh.exec!("logcopy #{self.app.name.downcase} #{Date.today - 7} | xargs cat > ~/#{self.ip}.log")
      ssh.exec!("gzip ~/#{self.ip}.log") || ""
    end
  end
  
  def download_logs
    Net::SCP.start(self.ip, self.user) do |scp|
      scp.download! "~/#{self.ip}.log.gz", "./#{self.ip}.log.gz"
    end
    
    `gunzip #{self.ip}.log.gz`
  end
end
