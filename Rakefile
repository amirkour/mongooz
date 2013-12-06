task :default=>:dev

# during dev, auto-rebuild please
task :dev=>[:rebuild,:test]{ puts "DEV MODE HOOOO!" }

# during prod - i dunno, do cool stuff
# TODO
task :prod do
	puts "I'm unimplemente thank you very much!"
end

task :test do
	puts "Running all tests!"
	Dir.glob("specs/**/*.rb").each do |spec_file|
		puts "Running #{spec_file}"
		system "rspec -fd #{spec_file}"
	end
end

task :rebuild => :clean do
	puts "Rebuilding ..."
	puts " *** WARNING *** - gem version is currently hardcoded!"
	system "gem build mongooz.gemspec"
	system "gem install mongooz-0.0.3.gem"#todo - version on cmd-line maybe?
end

task :clean do
	puts "Cleaning ..."
	# TODO - uninstall the gem every time?
end
