# encoding: UTF-8
module MongoMapper
  module Extensions
    module Symbol
      def serialize(value)
        to_mongo(value)
      end

      def deserialize(value)
        from_mongo(value)
      end

      def cast(value)
        to_mongo(value)
      end

      def to_mongo(value)
        value && value.to_s.to_sym
      end

      def from_mongo(value)
        value && value.to_s.to_sym
      end

      def changed?(old, new, _new_before_type_cast)
        old != new
      end

      def changed_in_place?(_old, _new)
        false
      end

      def assert_valid_value(value)
        value.respond_to? :to_sym
      end
    end
  end
end

class Symbol
  extend MongoMapper::Extensions::Symbol
end
