# encoding: UTF-8
module MongoMapper
  module Extensions
    module Boolean
      Mapping = {
        true    => true,
        'true'  => true,
        'TRUE'  => true,
        'True'  => true,
        't'     => true,
        'T'     => true,
        '1'     => true,
        1       => true,
        1.0     => true,
        false   => false,
        'false' => false,
        'FALSE' => false,
        'False' => false,
        'f'     => false,
        'F'     => false,
        '0'     => false,
        0       => false,
        0.0     => false,
        nil     => nil
      }

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
        Mapping[value]
      end

      def from_mongo(value)
        return nil if value == nil
        !!value
      end

      def assert_valid_value(_); end

      def changed_in_place?(_old, _new)
        false
      end

      def changed?(old, new, _new_before_type_cast)
        old != new
      end
    end
  end
end

class Boolean; end unless defined?(Boolean)

Boolean.extend MongoMapper::Extensions::Boolean

class ActiveModel::Type::Boolean
  include MongoMapper::Extensions::Boolean
end
