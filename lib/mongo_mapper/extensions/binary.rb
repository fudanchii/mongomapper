# encoding: UTF-8
module MongoMapper
  module Extensions
    module Binary
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
        if value.instance_of?(::BSON::Binary)
          value
        else
          value = nil if value.class == ::Object
          value.nil? ? nil : ::BSON::Binary.new(value)
        end
      end

      def from_mongo(value)
        value
      end

      def changed?(old, new, _new_without_cast)
        old&.data != new&.data
      end

      def changed_in_place?(old, new)
        false
      end
    end
  end
end

class Binary
  extend MongoMapper::Extensions::Binary
end

class ActiveModel::Type::Binary
  include MongoMapper::Extensions::Binary
end
