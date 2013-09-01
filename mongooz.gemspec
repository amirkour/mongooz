Gem::Specification.new do |s|
	s.name="mongooz"
	s.version="0.0.1"
	s.authors=["amir kouretchian"]
	s.date=%q{2013-08-08}
	s.description="Quick-n-easy mongo hashes."
	s.summary=s.description
	s.files=%w(README lib/mongooz.rb specs/mongooz_base_spec.rb specs/mongooz_hash_spec.rb)
	s.add_dependency('mongo')
	s.add_dependency('activerecord')
end
