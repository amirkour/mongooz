require 'mongooz'

module Mongooz
	module Test
		class TestHash<Mongooz::ActiveMongoozHash; end
	end
end

describe Mongooz::ActiveMongoozHash do
	before :all do
		# ensure that there's a clean collection to test on
		Mongooz::Base.db{|db| db.drop_collection("testhash")}
	end

	describe "TestHash objects" do
		it "is a HashWithIndifferentAccess" do
			expect(Mongooz::Test::TestHash.new).to be_a_kind_of(HashWithIndifferentAccess)
		end
		it "defaults to the testhash collection" do

			# construct a dummy TestHash object - I'll test if it in-fact
			# auto-inserts itself into the "TestHash" collection
			dummy=Mongooz::Test::TestHash.new.update({:name=>'random test name'})

			# manually access the "testhash" collection:
			Mongooz::Base.collection(:collection=>"testhash") do |col|

				# make sure it's clean before inserting the dummy object
				col.drop
				expect(col.count).to eq(0)

				# now insert the dummy object - it should auto-insert into the "TestHash" collection
				dummy.db_insert

				# did it?
				expect(col.count).to eq(1)

				# and finally, ensure collection is clean afterwards
				col.drop
			end
		end
		describe "::db_get_with_id" do
			before :all do
				@test_obj=Mongooz::Test::TestHash.new.update({:name=>"dummy test object"})
				@test_obj.db_insert
			end
			describe "with an existing _id" do
				it "returns a TestHash" do
					retrieved_object=Mongooz::Test::TestHash.db_get_with_id(:_id=>@test_obj[:_id])
					expect(retrieved_object).to be_a_kind_of(Mongooz::Test::TestHash)
				end
				it "returns a TestHash that is populated" do
					retrieved_object=Mongooz::Test::TestHash.db_get_with_id(:_id=>@test_obj[:_id])
					expect(retrieved_object[:name]).to_not be_nil
				end
			end

			describe "with a nonexisting _id" do
				it "returns nil" do
					retrieved_object=Mongooz::Test::TestHash.db_get_with_id(:_id=>BSON::ObjectId.new.to_s)
					expect(retrieved_object).to be_nil
				end
			end
		end
	end
end
