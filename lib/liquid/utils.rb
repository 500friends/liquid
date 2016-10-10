module Liquid
  module Utils
    def self.slice_collection_using_each(collection, from, to)
      segments = []
      index = 0
      yielded = 0

      # Maintains Ruby 1.8.7 String#each behaviour on 1.9
      return [collection] if non_blank_string?(collection)

      collection.each do |item|

        if to && to <= index
          break
        end

        if from <= index
          segments << item
        end

        index += 1
      end

      segments
    end

    def self.non_blank_string?(collection)
      collection.is_a?(String) && collection != ''
    end

    # supply an uuid, in the case where a unique key is passed in, it always supply the same id for that key
    def self.uuid(unique_key = nil)
      @uuid ||= 0
      @uuid_hashes ||= {}
      if unique_key && @uuid_hashes[unique_key]
        return @uuid_hashes[unique_key]
      else
        @uuid += 1
        new_id = "-_li#{@uuid}-"
        @uuid_hashes[unique_key] = new_id if unique_key
        new_id
      end
    end
  end
end
