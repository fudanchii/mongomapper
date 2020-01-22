# encoding: UTF-8
module MongoMapper
  module Extensions
    module Date
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
        if value.nil? || (value.instance_of?(String) && '' === value)
          nil
        else
          date = value.instance_of?(::Date) || value.instance_of?(::Time) ? value : ::Date.parse(value.to_s)
          ::Time.utc(date.year, date.month, date.day)
        end
      rescue
        nil
      end

      def from_mongo(value)
        value.to_date if value
      end

      def changed?(old, new, _new_before_type_cast)
        old.to_i != new.to_i
      end

      def changed_in_place?(old, new)
        false
      end
    end
  end
end

class Date
  extend MongoMapper::Extensions::Date
end

class ActiveModel::Type::Date
  include MongoMapper::Extensions::Date
end
