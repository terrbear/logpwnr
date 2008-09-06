#!/usr/bin/ruby

Math.module_eval do
	def self.variance(population)
		n = 0
		mean = 0.0
		s = 0.0
		population.each do |x|
			n += 1
			delta = x - mean
			mean = mean + (delta / n)
			s = s + delta * (x - mean)
		end
		return s / n
	end

	def self.stddev(population)
		Math.sqrt(Math.variance(population)) rescue (0.0/0.0)
	end
end

process_regex = /Processing (.*)? \(/
time_regex = /Completed in ([0-9].[0-9]*) .*? Rendering: ([0-9].[0-9]*) .*? DB: ([0-9].[0-9]*)/
actions = {}
last_action = Hash.new({})

class Stat
	attr_accessor :name, :hits
	attr_reader :actions, :renders, :dbs

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

	def total(type)
		if [:action, :render, :db].include?(type)
			return self.send(type.to_s + "s").inject(0){|sum, x| sum += x}
		elsif type == :total
			return total(:action) + total(:render) + total(:db)
		else
			return 0
		end
	end

	def average(type)
		if [:action, :render, :db].include?(type)
		 	return total(type) / self.send(type.to_s + "s").size.to_f
		elsif type == :total
			avg = (average(:action) + average(:render) + average(:db)).to_f
			return avg.to_s == "NaN" ? 0 : avg
		else
			return 0
		end
	end

	def stddev(type)
		if [:action, :render, :db].include?(type)
			return Math.stddev(self.send(type.to_s + "s"))
		else
			return 0	
		end
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

action_names = actions.keys.sort{|a,b| actions[a].average(:total) <=> actions[b].average(:total)}.reverse
puts "name,hits,action avg,action avg stddev,render avg,render avg stddev,db avg,db avg stddev,total avg,action,render,db,total"
action_names.each do |action|
	a = actions[action]
	puts [a.name, a.hits, 
				format(a.average(:action)), format(a.stddev(:action)),
				format(a.average(:render)), format(a.stddev(:render)),
				format(a.average(:db)), format(a.stddev(:db)),
				format(a.average(:total)), format(a.total(:action)), format(a.total(:render)), 
				format(a.total(:db)), format(a.total(:total))].join(",")
end
