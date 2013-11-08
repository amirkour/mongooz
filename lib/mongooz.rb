require 'mongo'
require 'active_support/core_ext/hash/indifferent_access'
include Mongo

module Mongooz

	@DEFAULT_DB='test'
	@DEFAULT_HOST='localhost'
	@DEFAULT_PORT=27017
	@DEFAULT_USER=nil
	@DEFAULT_PASSWORD=nil

	class << self
		attr_reader :DEFAULT_DB, :DEFAULT_HOST, :DEFAULT_PORT, :DEFAULT_USER, :DEFAULT_PASSWORD
		def defaults(options={})
			@DEFAULT_DB=options[:db] if options[:db]
			@DEFAULT_HOST=options[:host] if options[:host]
			@DEFAULT_PORT=options[:port] if options[:port]
			@DEFAULT_USER=options[:user] if options[:user]
			@DEFAULT_PASSWORD=options[:password] if options[:password]
			{:host=>@DEFAULT_HOST, :port=>@DEFAULT_PORT, :db=>@DEFAULT_DB, :user=>@DEFAULT_USER, :password=>@DEFAULT_PASSWORD}
		end
	end

	module Base
		class << self
			def client(options = {}, &block)
				host=options[:host] || Mongooz.DEFAULT_HOST
				port=options[:port] || Mongooz.DEFAULT_PORT

				client=MongoClient.new(host,port)

				return client unless block
				begin
					block.call(client)
				ensure
					client.close
				end
			end
			def db(options = {}, &block)
				db_host=options[:host] || Mongooz.DEFAULT_HOST
				db_port=options[:port] || Mongooz.DEFAULT_PORT
				db_name=options[:db] || Mongooz.DEFAULT_DB
				db_user=options[:user] || Mongooz.DEFAULT_USER
				db_password=options[:password] || Mongooz.DEFAULT_PASSWORD

				client=Mongooz::Base::client({:host => db_host, :port => db_port})
				db_to_ret=client[db_name]
				db_to_ret.authenticate(db_user,db_password) if db_user && db_password
				return db_to_ret unless block
				begin
					block.call(client[db_name])
				ensure
					client.close
				end
			end
			def collection(options={}, &block)
				db_host=options[:host] || Mongooz.DEFAULT_HOST
				db_port=options[:port] || Mongooz.DEFAULT_PORT
				db_name=options[:db] || Mongooz.DEFAULT_DB
				collection_name=options[:collection]
				raise "Missing required :collection parameter" unless collection_name

				db=Mongooz::Base::db(:host => db_host, :port => db_port, :db => db_name)
				return db[collection_name] unless block
				begin
					block.call(db[collection_name])
				ensure
					db.connection.close
				end
			end
		end
	end# Base

	# TODO - comment mah!
	class MongoozHash < HashWithIndifferentAccess

		class << self
			def get_class_name_without_namespace(class_to_retrieve_name_from)
				return nil unless class_to_retrieve_name_from.respond_to?(:name)
				class_to_retrieve_name_from.name.split("::").last.downcase
			end

			# will use Mongooz.defaults where they are missing in the given hash
			def set_db_options(options)
				options[:collection]=options[:collection] || MongoozHash.get_class_name_without_namespace(self)
				options[:db]=options[:db] || Mongooz.DEFAULT_DB
				options[:host]=options[:host] || Mongooz.DEFAULT_HOST
				options[:port]=options[:port] || Mongooz.DEFAULT_PORT
				options[:user]=options[:user] || Mongooz.DEFAULT_USER
				options[:password]=options[:password] || Mongooz.DEFAULT_PASSWORD
				options
			end

			def typified_result_hash_or_nil(hash_to_wrap)
				return nil unless hash_to_wrap.kind_of?(Hash)
				self.new.update(hash_to_wrap)
			end

			def db_query(query={},query_opts={},options={})
				query={} unless query.kind_of?(Hash)
				query_opts={} unless query_opts.kind_of?(Hash)
				set_db_options(options)
				results=[]
				Mongooz::Base.collection(options) do |col|
					col.find(query,query_opts).each do |next_result|
						typed_result=typified_result_hash_or_nil(next_result)
						results << typed_result if typed_result
					end
				end

				results.length > 0 ? results : nil
			end

			def db_get_with_id(options={})
				id=options[:_id]
				raise "Missing required :_id options parameter" unless id

				set_db_options(options)
				result=nil
				Mongooz::Base.collection(options) do |col|
					result=col.find_one(:_id => id)
				end

				typified_result_hash_or_nil(result)
			end

			def db_get_with_bson_string(bson_string, options={})
				bson_id=nil
				begin
					bson_id=BSON.ObjectId(bson_string)
				rescue
					raise "Expected string #{bson_string.to_s} to be a valid bson id"
				end
				raise "Failed to bson-ify #{bson_string.to_s}" if bson_id.nil?

				set_db_options(options)
				result=nil
				Mongooz::Base.collection(options) do |col|
					result=col.find_one(:_id => bson_id)
				end

				typified_result_hash_or_nil(result)
			end

			def db_get_paged(query={}, options={})
				query={} unless query.kind_of?(Hash)
				max_page_size=100    # bugbug - configurable?
				page=options[:page] || 0
				raise "Page number must be a non-negative number" unless page >= 0

				page_size=options[:page_size] || max_page_size # bugbug - configurable?
				raise "Page size must be a positive number not exceeding #{max_page_size}" unless(page_size <= max_page_size && page_size > 0)

				num_to_skip=page * page_size
				set_db_options(options)

				results=[]
				Mongooz::Base.collection(options) do |col|

					# this is probably how best to do paging but it requires you keep track of
					# an anchor element, and a minimum anchor value, and the last element of the
					# previous page
					# col.find({:value=>{:$gte=>30}}, {:limit=>20,:sort=>{:value=>:asc}}).each{|x| puts x}

					# this is a lot easier to maintain, off the bat.  seeking is also really inefficient as you get up there in pages
					cursor=col.find( query, {:limit => page_size, :skip=>num_to_skip})
					cursor.each do |next_result|
						typed_result=typified_result_hash_or_nil(next_result)
						results << typed_result if typed_result
					end
				end

				results.length > 0 ? results : nil
			end
		end

		def set_db_options(options)
			self.class.set_db_options(options)
		end

		def db_insert(options={})
			set_db_options(options)
			id=nil
			Mongooz::Base.collection(options) do |col|
				id=col.insert(self)
			end

			id
		end

		# probably not very useful - most of your update APIs should be targeted for performance.
		# this one will "replace" the given id with the contents of self.
		# you can use this API for upserts too, just pass :upsert=>true in the options hash.
		# behavior will differ on the upsert depending on whether or not the given id exists.
		def db_update(options={})
			do_upsert=options[:upsert]==true
			if self[:_id].nil? && !do_upsert
				raise "Cannot update w/o :_id hash param"
			end

			set_db_options(options)
			err_hash=nil
			Mongooz::Base.collection(options) do |col|
				err_hash=col.update({:_id=>self[:_id]}, self, options)
			end

			raise "Didn't get an error hash from update api?" if err_hash.nil?
			raise "Didn't get an error hash that was a hash object from update api?" unless err_hash.kind_of?(Hash)
			raise "Didn't get an error hash with an 'n' key from update api?" unless err_hash['n']
			return err_hash['n'] > 0
		end

		# deletes everything matching delete_query from a collection.
		# 
		# the options hash takes db/connection/host/port, as well as any options to the delete api.
		#
		# delete_query has to be a hash.  if it's absent, this API will delete all docs
		# with _id=self[:_id].  If no such _id exists, raises an error.
		def db_delete(delete_query=nil, options={})
			query=nil
			if(delete_query.nil?)
				id=self[:_id]
				raise "Cannot delete without an _id" unless id
				query={:_id=>id}
			else
				raise "Delete query must be a hash" unless delete_query.kind_of?(Hash)
				query=delete_query
			end
			
			set_db_options(options)
			err_hash=nil
			Mongooz::Base.collection(options) do |col|
				err_hash=col.remove(query,options)
			end

			raise "Didn't get an error hash from delete api?" if err_hash.nil?
			raise "Didn't get an error hash that was a hash object from delete api?" unless err_hash.kind_of?(Hash)
			raise "Didn't get an error hash with an 'n' key from delete api?" unless err_hash['n']
			return err_hash['n'] > 0
		end
	end
end
