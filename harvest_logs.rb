task :harvest_logs, :roles => :app do
	`rm -f *.log *.log.gz *.csv`
	original = ENV['HOSTS']
	find_servers(:roles => :app).collect{|d| d.host}.each do |host|
		ENV['HOSTS'] = host
		run "rm -f /home/#{user}/*.log /home/#{user}/*.log.gz"
		sudo "/#{user}/logcopy.rb #{application} #{Date.today - 7} | xargs cat > /home/#{user}/#{host}.log"
		run "gzip /home/#{user}/#{host}.log"
		get "/home/#{user}/#{host}.log.gz", "./#{host}.log.gz"
		`gunzip #{host}.log.gz`
	end
  
  emails = [] #put in emails here to have them sent out automagically
  
	`cat *.log > #{app_env}.log`
	`echo "Subject: #{app_env} performance" > #{app_env}.csv`
	`ruby script/logpwnr.rb #{app_env}.log >> #{app_env}.csv`
	`cat #{app_env}.csv | sendmail #{emails.join(',')}`
end