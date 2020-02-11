# encoding: UTF-8
require 'set'

module MongoMapper
  module Extensions
    module Set
      def deserialize(value)
        from_mongo(value)
      end

      def serialize(value)
        to_mongo(value)
      end

      def cast(value)
        to_mongo(value)
      end

      def to_mongo(value)
        value.to_a
      end

      def from_mongo(value)
        (value || []).to_set
      end

      def assert_valid_value(_)
      end
    end
  end
end

class Set
  extend MongoMapper::Extensions::Set
end
