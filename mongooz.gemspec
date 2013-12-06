Gem::Specification.new do |s|
	s.name="mongooz"
	s.version="0.0.3"
	s.authors=["amir kouretchian"]
	s.date=%q{2013-11-10}
	s.description="Quick-n-easy mongo hashes."
	s.summary=s.description
	s.files=%w(README.md).concat(Dir.glob("**/*.rb"))
	s.add_dependency('mongo')
	s.add_dependency('activerecord')
end
