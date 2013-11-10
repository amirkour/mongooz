require 'mongooz'

# properties are purely for human-readable convenience.
# the getter "foo" is just fronting access to self[:foo]
# in a MongooHash (guess what the setter does!?)
#
# use properties to describe the structure of your MongoozHash implementations
class PropertyTester<Mongooz::MongoozHash
	getter :foo
	setter :bar
	property :fname,:lname,"mname"
end

describe "Mongooz::Hash properties" do
	describe "getters" do
		it "are backed by their equivalent hash keys" do
			test=PropertyTester.new

			# write to the hash key 'foo' explicitly
			test[:foo]="hi"

			# and then retrieve it via getter
			expect(test.foo).to eq("hi")
		end
	end
	describe "setters" do
		it "write to their equivalent hash keys" do
			test=PropertyTester.new

			# first, write to the 'bar' key
			test[:bar]="should get overwritten"

			# now overwrite it with the setter
			test.bar="foo"

			# and verify that it simply blew away test[:bar]
			expect(test[:bar]).to eq("foo")
		end
	end
	describe "properties" do
		it "provide getters" do
			test=PropertyTester.new
			test[:fname]="hi"
			expect(test.fname).to eq("hi")
		end
		it "provide setters" do
			test=PropertyTester.new
			test[:fname]="asfasdf"
			test.fname="hi"
			expect(test[:fname]).to eq("hi")
		end

		# this one is just a sanity check to make sure that the following notation does what it's supposed to:
		# property :fname,:lname,"mname"
		it "can be specified in a list, instead of one-by-one" do
			test=PropertyTester.new({:fname=>"bla",:lname=>"blab",:mname=>"blaz"})
			expect(test.fname).to eq("bla")
			expect(test.lname).to eq("blab")
			expect(test.mname).to eq("blaz")
		end
	end
end