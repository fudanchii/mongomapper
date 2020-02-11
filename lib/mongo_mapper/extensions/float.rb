# encoding: UTF-8
module MongoMapper
  module Extensions
    module Float
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
        value.blank? ? nil : value.to_f
      end

      def changed?(old, new, _new_value_before_type_cast)
        old != new
      end

      def changed_in_place?(old, new)
        false
      end
    end
  end
end

class Float
  extend MongoMapper::Extensions::Float
end

class ActiveModel::Type::Float
  include MongoMapper::Extensions::Float
end
