#!/usr/local/bin/ruby

require 'date'

logdir = "/var/www/apps/#{ARGV[0]}/shared/log"
start_date = Date.parse(ARGV[1]) rescue Date.today
date_regex = (start_date .. Date.today).collect{|x| x.to_s}.join('|')
regex = /production.log.#{date_regex}/
Dir.new(logdir).entries.each do |entry|
	puts "#{logdir}/#{entry}" if (entry =~ regex || entry =~ /production.log$/) && !(entry =~ (/brb/))
end
