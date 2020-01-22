# encoding: UTF-8
module MongoMapper
  module Extensions
    module Integer
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
        value_to_i = value.to_i
        if value_to_i == 0 && value != value_to_i
          value.to_s =~ /^(0x|0b)?0+/ ? 0 : nil
        else
          value_to_i
        end
      end

      def from_mongo(value)
        value && value.to_i
      end

      def changed_in_place?(old, new)
        from_mongo(old) != new
      end

      def changed?(old, new, _new_value_before_type_cast)
        old != new
      end
    end
  end
end

class Integer
  extend MongoMapper::Extensions::Integer
end

class ActiveModel::Type::Integer
  include MongoMapper::Extensions::Integer
end
