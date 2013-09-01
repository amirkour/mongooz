Mongooz provides quick-n-easy mongo hashes: CRUD ops on the ruby mongo driver in the form of a HashWithIndifferentAccess.

class CoolClass < Mongooz::MongoozHash
end

a=CoolClass.new
a[:foo]='bar'
a.db_insert

You now have a collection called 'coolclass' in the 'test' mongo database being hosted on localhost:27017.
Change default options like so:

Mongooz.defaults :db=>'cooldb', :host=>'coolhost', :port=>123123
a.db_insert

Now you have a collection called 'coolclass' in the 'cooldb' mongo database being hosted on coolhost:123123.

With user/passy:
Mongooz.defaults :user=>'cool_user', :password=>'cool_password'
a.db_insert

All subclasses of MongoozHash are using Mongooz::Base for connection, db, and collection objects:
Mongooz::Base.collection({:collection=>"coolclass"}) do |con|
	my_foo=con.find_one({:foo=>"bar"})
	puts "#{my_foo}"
end

Or grab the DB and go to work:
Mongooz::Base.db do |authenticated_db|
	foo_collection=authenticated_db['coolclass']
	...
end
