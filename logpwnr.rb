#!/usr/bin/ruby

process_regex = /Processing (.*)? \(/
time_regex = /Completed in ([0-9].[0-9]*) .*? Rendering: ([0-9].[0-9]*) .*? DB: ([0-9].[0-9]*)/
actions = {}
last_action = Hash.new({})

class Stat
	attr_accessor :name, :hits
	def initialize(name)
		self.name = name
		@actions = []
		@renders = []
		@dbs = []
		@hits = 0
	end

	def add_stat(action, render, db)
		@actions << action.to_f unless action.to_f == 0
		@renders << render.to_f unless render.to_f == 0
		@dbs << db.to_f unless db.to_f == 0
	end

	def hit!
		@hits += 1
	end

	def total_action_time
		@actions.inject(0){|sum, x| sum += x} 
	end

	def total_render_time
		@renders.inject(0){|sum, x| sum += x} 
	end

	def total_db_time
		@dbs.inject(0){|sum, x| sum += x} 
	end

	def total_time
		total_action_time + total_render_time + total_db_time
	end

	def average_action_time
		total_action_time / @actions.size.to_f
	end

	def average_render_time
		total_render_time / @renders.size.to_f
	end

	def average_db_time
		total_db_time / @dbs.size.to_f
	end

	def average_total_time
		avg = (average_action_time + average_render_time + average_db_time).to_f
		avg.to_s == "NaN" ? 0 : avg
	end
end

File.open(ARGV[0], 'r').each do |line|
	next unless line

	if action = line[process_regex, 1]
		actions[action] ||= Stat.new(action)
		actions[action].hit!
		last_action = action
	end

	if line =~ time_regex && last_action
		actions[last_action].add_stat(line[time_regex, 1], line[time_regex, 2], line[time_regex, 3])
		last_action = nil
	end
end

def format(num)
	sprintf("%.5f", num)
end

action_names = actions.keys.sort{|a,b| actions[a].average_total_time <=> actions[b].average_total_time}.reverse
puts "name,hits,action (avg),render (avg),db (avg),total (avg),action,render,db,total"
action_names.each do |action|
	a = actions[action]
	puts [a.name, a.hits, format(a.average_action_time), format(a.average_render_time), format(a.average_db_time),
				format(a.average_total_time), format(a.total_action_time), format(a.total_render_time), 
				format(a.total_db_time), format(a.total_time)].join(",")
end
