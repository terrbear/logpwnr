set :svn_ip, "72.249.82.8"
set :repository,  "svn://#{svn_ip}/kalivo/trunk"

MEMCACHED_PORTS = {
  "apple" => "11211", "bmc" => "11212", "bsg" => "11213", 
  "bsgalliance" => "11214", "dell" => "11215", "elo" => "11216", 
  "kalivo" => "11217", "m_one" => "11218", "members" => "11219", 
  "ni" => "11220", "rome" => "11221", "solidworks" => "11222", "merck" => "11223",
  "strategy" => "11224", "jnj" => "11225", "hmh" => "11226", "idea" => "11227", 
  "ngenera" => "11228", "owenscorning" => "11229", "staging" => "11230"
}

APP_ENVS = {
	"ngenera" => ["72.249.37.200", "72.249.37.248", "72.249.37.174", "72.249.37.243"],
  "bsgalliance" => ["72.249.37.146", "72.249.37.249", "72.249.37.201", "72.249.37.244"],  
  "members" => ["72.249.37.147", "72.249.37.250", "72.249.37.202", "72.249.37.245"],  
	"idea" => ["72.249.37.148"],
	"jnj" => ["72.249.37.200"],
  "solidworks" => ["65.99.223.221"],
  "dell" => ["72.249.82.11"],
  "hmh" => ["72.249.82.13"],
  "owenscorning" => ["72.249.82.13"],
  "staging" => ["72.249.82.13"],
  "kalivo" => ["72.249.82.8"],
  "rome" => ["72.249.21.80"],
  "merck" => ["72.249.21.175"]
}

DB_ENVS = {
	"ngenera" => ["72.249.37.200"],
  "bsgalliance" => ["72.249.37.146"],
  "members" => ["72.249.37.147"],
	"idea" => ["72.249.37.148"],
	"jnj" => ["72.249.37.200"],
  "solidworks" => ["65.99.223.221"],
  "dell" => ["72.249.82.11"],
  "hmh" => ["72.249.82.13"],
  "owenscorning" => ["72.249.82.13"],
  "staging" => ["72.249.82.13"],
  "kalivo" => ["72.249.82.8"],
  "rome" => ["72.249.21.80"],
  "merck" => ["72.249.21.175"]
}

WEB_ENVS = {
	"ngenera" => ["72.249.37.200", "72.249.37.248", "72.249.37.174", "72.249.37.243"],  
  "bsgalliance" => ["72.249.37.146", "72.249.37.249", "72.249.37.201", "72.249.37.244"],  
  "members" => ["72.249.37.147", "72.249.37.250", "72.249.37.202", "72.249.37.245"],  
	"idea" => ["72.249.37.148"],
	"jnj" => ["72.249.37.200"],
  "solidworks" => ["65.99.223.221"],
  "dell" => ["72.249.82.11"],
  "hmh" => ["72.249.82.13"],
  "owenscorning" => ["72.249.82.13"],
  "staging" => ["72.249.82.13"],
  "kalivo" => ["72.249.82.8"],
  "rome" => ["72.249.21.80"],
  "merck" => ["72.249.21.175"]
}

#role :app, "#{ip}"
#role :web, "#{ip}" #not doing anything here yet
#role :db,  "#{ip}", :primary => true #not doing anything here yet

set :svn_username, "deployer"
set :svn_password, "byronbay"

set :user, "deployer"
set :password, "byronbay"

task :establish_target do
	env = ENV['env']

	if env.to_s.strip == ""
		env = Capistrano::CLI.ui.ask "what environment? (#{APP_ENVS.keys.join(', ')})"
	end

	if env != "staging"
		confirm = Capistrano::CLI.ui.ask "are you sure? this is kind of a big deal. (type YES, in caps)."
		if confirm != "YES"
			puts "ok, that's cool. we'll bail then."
			exit 1
		end
	end

	exit 1 unless APP_ENVS.keys.include?(env)

	role :app, *APP_ENVS[env]
	role :db, DB_ENVS[env].first, :primary => true
	role :web, *WEB_ENVS[env]

	set :app_env, env
	set :deploy_to, "/var/www/apps/#{env}"
	set :application, env
  set :site_config, "/var/www/apps/site_config"
	
end
	
def rake(cmd)
	run "cd #{deploy_to}/current; /usr/local/bin/rake #{cmd}"
end

namespace :kalivo do
	task :make_backups_dir, :roles => :db do
		run "mkdir #{deploy_to}/database_backups"
	end

	task :backup_database, :roles => :db do
		backup_location = "#{deploy_to}/database_backups/#{app_env}_#{Time.now.to_s.gsub(/-/, '').gsub(/ /, '_')}.sql"
		run "mysqldump -uroot -ppassword12 -h127.0.0.1 --opt --single_transaction --database #{app_env} > #{backup_location}"
	end
	
	task :give_deployer_rights, :roles => :app do
		sudo "chown -R #{user}:#{user} /var/www/apps/#{application}/current"
	end
	
	task :get_config, :roles => :app do
		run "svn co svn://#{svn_ip}/kalivo/config/branches/#{app_env} #{release_path}/config"
    #copy files from site_config where appropriate (if site_config exists)
    run "cp -R #{site_config}/#{app_env}/* #{release_path}/config/." rescue nil
  
	end

	task :fix_permissions, :roles => :app do
		run "chmod +x #{release_path}/script/runner"
		run "chmod +x #{release_path}/script/memcache_ctl"
	end
	
	task :clear_logs, :roles => :app do
		begin
		run "rm -f #{release_path}/log/*.log"
		rescue
			#just means no files were there to remove
		end
	end

	task :install_theme_overrides, :roles => :app do
		run "cp -R #{release_path}/themes/#{application}/images/for_public/* #{release_path}/public/images/ 2> /dev/null" rescue nil
		run "ln -s #{release_path}/public/stylesheets/images/default #{release_path}/public/images/default"		
    rake("theme_update_cache theme=#{application}")
	end

	task :clear_cache, :roles => :app do
		rake("tmp:cache:clear")
	end

	task :stop_services, :roles => :app do
		sudo "/usr/local/bin/monit -g brb stop all"
    sudo "/usr/local/bin/monit stop memcached_#{MEMCACHED_PORTS[application]}"
		sudo "/usr/local/bin/monit -g mongrel_#{application} stop all"		
	end

	task :start_services, :roles => :app do
    sudo "/usr/local/bin/monit start memcached_#{MEMCACHED_PORTS[application]}"    
	  sudo "/usr/local/bin/monit -g mongrel_#{application} start all"
		sudo "/usr/local/bin/monit -g brb start all"
	end

	task :restart_apache, :roles => :web do
		sudo "/etc/init.d/httpd restart"
	end

	task :give_apache_rights, :roles => :app do
		sudo "chown -R apache:apache /var/www/apps/#{application}/current"
	end

	task :harvest_logs, :roles => :app do
		`rm -f *.log *.log.gz *.csv`
		original = ENV['HOSTS']
		find_servers(:roles => :app).collect{|d| d.host}.each do |host|
			ENV['HOSTS'] = host
			run "rm -f /home/deployer/*.log /home/deployer/*.log.gz"
			sudo "/root/logcopy.rb #{application} #{Date.today - 7} | xargs cat > /home/deployer/#{host}.log"
			run "gzip /home/deployer/#{host}.log"
			get "/home/deployer/#{host}.log.gz", "./#{host}.log.gz"
			`gunzip #{host}.log.gz`
		end
		emails = ['mroeder@ngenera.com', 
							'rdejuana@ngenera.com', 
							'jcobb@ngenera.com', 
							'mschriftman@ngenera.com',
							'sbrittain@ngenera.com',
							'jbell@ngenera.com',
							'arahim@ngenera.com',
							'theath@ngenera.com']

		`cat *.log > #{app_env}.log`
		`echo "Subject: #{app_env} performance" > #{app_env}.csv`
		`ruby script/logpwnr.rb #{app_env}.log >> #{app_env}.csv`
		`cat #{app_env}.csv | sendmail #{emails.join(',')}`
	end

	task :status, :roles => :app do
		original = ENV['HOSTS']
		find_servers(:roles => :app).collect{|d| d.host}.each do |h|
			ENV['HOSTS'] = h
			rake 'status'	
		end
		ENV['HOSTS'] = original
	end
end

namespace :deploy do
	task :restart do
		#nothing
	end
end

#steps for deployment from rake task (old way):
#1)  converts to maintenance mode
#2)  stops memcached, backgroundrb, mongrels
#3)  backs up database
#4)  updates code
#5)  runs migrations
#6)  makes script/runner executable
#7)  clears logs
#8)  copies theme overrides over from app/themes/app/images/for_public to public/images
#9)  symlinks css images
#10)  starts memcached, backgroundrb, mongrels
#11) turns off maintenance mode
#12) restarts apache
#13) checks for svn conflicts

#new steps, how they're handled
#1)  cap deploy:web:disable
#2)  kalivo:stop_services
#3)  kalivo:backup_database
#4)  deploy
#5)  deploy:migrate
#6)  kalivo:fix_permissions
#7)  log:clear
#8)  kalivo:install_theme_overrides
#9)  (handled by #8)
#10)  kalivo:start_services
#11)  deploy:web:enable
#12)  kalivo:restart_apache
#13)  not applicable (it's a new checkout each time)

before_deploy_tasks = ['establish_target',
									'kalivo:give_deployer_rights',
									'deploy:web:disable',
									'kalivo:stop_services',
									'kalivo:backup_database'
									]

after_deploy_tasks = ['kalivo:get_config',
											'deploy:migrate',
											'kalivo:fix_permissions',
											'kalivo:clear_logs',
											'kalivo:install_theme_overrides',
											'kalivo:clear_cache',
											'kalivo:start_services',
											'deploy:web:enable',
											'kalivo:restart_apache'
											]

#set this for the maintenance page so everybody knows to ping scott with questions.
before "deploy:cold", 'establish_target'
ENV['UNTIL'] = "soon. Please contact mroeder@ngenera.com with any questions."
before "deploy", *before_deploy_tasks
after "deploy", *after_deploy_tasks

before 'deploy:setup', :establish_target
after 'deploy:setup', 'kalivo:make_backups_dir'

before 'kalivo:harvest_logs', :establish_target

before 'kalivo:status', :establish_target
