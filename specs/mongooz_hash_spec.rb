require 'mongooz'
module Mongooz
	module Test
		class TestHash<Mongooz::MongoozHash
		end
	end
end

describe Mongooz::MongoozHash do
	describe "TestHash (child of MongoozHash)" do
		before :all do
			@test_obj=Mongooz::Test::TestHash.new
		end
		it "is a HashWithIndifferentAccess" do
			expect(@test_obj).to be_a_kind_of(HashWithIndifferentAccess)
		end
		describe "default collection" do
			before :all do
				Mongooz::Base.collection(:collection=>'testhash'){|col| col.drop}
			end
			it "defaults to the testhash collection" do
				dummy={:_id=>'foo'}
				Mongooz::Base.collection(:collection=>"testhash") do |col|
					expect(col.count).to eq(0)
					col.insert(dummy)
					expect(col.count).to eq(1)
				end

				expect(Mongooz::Test::TestHash.db_get_with_id(:_id=>dummy[:_id])).to_not be_nil
			end
		end
	end
end
