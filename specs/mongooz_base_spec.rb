
require 'mongooz'

describe Mongooz do
	before :all do
		@DEFAULT_DB='test'
		@DEFAULT_HOST='localhost'
		@DEFAULT_PORT=27017
	end

	describe '.DEFAULT_HOST' do
		it 'is read-only' do
			expect{Mongooz.DEFAULT_HOST='hi'}.to raise_error
			expect(Mongooz.DEFAULT_HOST).to be_an_instance_of(String)
		end
		it "is set to localhost by default" do
			expect(Mongooz.DEFAULT_HOST).to eq(@DEFAULT_HOST)
		end
	end
	describe ".DEFAULT_PORT" do
		it 'is read-only' do
			expect{Mongooz.DEFAULT_PORT='hi'}.to raise_error
			expect(Mongooz.DEFAULT_PORT).to be_an_instance_of(Fixnum)
		end
		it "is set to 27017 by default" do
			expect(Mongooz.DEFAULT_PORT).to eq(@DEFAULT_PORT)
		end
	end
	describe ".DEFAULT_DB" do
		it 'is read-only' do
			expect{Mongooz.DEFAULT_DB='hi'}.to raise_error
			expect(Mongooz.DEFAULT_DB).to be_an_instance_of(String)
		end
		it "is set to test by default" do
			expect(Mongooz.DEFAULT_DB).to eq(@DEFAULT_DB)
		end
	end
	describe '::Base' do
		describe '::client' do
			describe 'without configuration options' do
				context 'without a block' do
					before :all do
						@client=Mongooz::Base.client
					end
					after :all do
						@client.close
					end

					it 'returns a connection' do
						expect(@client).to_not be_nil
						expect(@client).to be_connected
					end

					it "returns a connection talking to host #{Mongooz.DEFAULT_HOST}" do
						expect(@client.host).to eq(Mongooz.DEFAULT_HOST)
					end

					it "returns a connection talking on port #{Mongooz.DEFAULT_PORT}" do
						expect(@client.port).to eq(Mongooz.DEFAULT_PORT)
					end
				end

				context 'with a block' do
					it 'should yield' do

						# block should yield, passing an argument of type Mongo::MongoClient into the block
						expect {|b| Mongooz::Base.client(&b) }.to yield_with_args(Mongo::MongoClient)
					end
				end
			end
			describe 'with configuration options' do
				before :all do
					@host="127.0.0.1"
					@port=27017
					@client=Mongooz::Base.client({:host => @host,:port => @port})
				end
				after :all do
					@client.close
				end
				context 'without a block' do
					it 'returns a connection' do
						expect(@client).to_not be_nil
						expect(@client).to be_connected
					end
					it "returns a connection talking to host #{@host}" do
						expect(@client.host).to eq(@host)
					end

					it "returns a connection talking on port #{@port}" do
						expect(@client.port).to eq(@port)
					end
				end
				context 'with a block' do
					it 'should yield' do

						# block should yield, passing an argument of type Mongo::MongoClient into the block
						expect {|b| Mongooz::Base.client({:host => @host,:port => @port}, &b) }.to yield_with_args(Mongo::MongoClient)
					end
				end
			end
		end# ::client
		describe "::db" do
			context 'without any args' do
				before :all do
					@db=Mongooz::Base.db
				end
				after :all do
					@db.connection.close
				end
				it 'should be an instance of Mongo::DB' do
					expect(@db).to be_an_instance_of(Mongo::DB)
				end
				it "should be pointed at the #{Mongooz.DEFAULT_DB} database" do
					expect(@db.name).to eq(Mongooz.DEFAULT_DB)
				end
				it "should yield with a block" do
					expect {|b| Mongooz::Base.db(&b) }.to yield_with_args(Mongo::DB)
				end
			end
			context "with db arg" do
				before :all do
					@db_name='foo'
					@db=Mongooz::Base.db(:db => @db_name)
				end
				it "should be an instance of Mongo::DB" do
					expect(@db).to be_an_instance_of(Mongo::DB)
				end
				it "should be pointed at the '#{@db_name}' database" do
					expect(@db.name).to eq(@db_name)
				end
				it "should yield with a block" do
					expect {|b| Mongooz::Base.db(:db => @db_name, &b) }.to yield_with_args(Mongo::DB)
				end
			end
		end# end ::db
		describe "::collection" do
			before :all do
				@collection_fake='nonexisting'
				@collection_test='mongooz_test_collection_spec_collection'
				Mongooz::Base.db do |db|
					db[@collection_test].insert({:foo=>'bar'})
				end
			end
			after :all do
				Mongooz::Base.db do |db|
					db.drop_collection(@collection_test)
				end
			end
			it "raises an error without a collection name" do
				expect{Mongooz::Base.collection}.to raise_error
			end
			it "returns an object of type Mongo::Collection for fake collection #{@collection_fake}" do
				expect(Mongooz::Base.collection(:collection => @collection_fake)).to be_an_instance_of(Mongo::Collection)
			end
			it "returns an object of type Mongo::Collection for test collection #{@collection_test}" do
				expect(Mongooz::Base.collection(:collection => @collection_test)).to be_an_instance_of(Mongo::Collection)
			end
			it "returns a non-empty collection for test collection #{@collection_test}" do
				expect(Mongooz::Base.collection(:collection => @collection_test).count).to be > 0 
			end
			it "should yield with a block" do
				expect{|b| Mongooz::Base.collection(:collection => 'mumble', &b) }.to yield_with_args(Mongo::Collection)
			end
		end
	end
end
