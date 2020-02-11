# encoding: UTF-8
module MongoMapper
  module Extensions
    module ObjectId
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
        Plucky.to_object_id(value)
      end

      def from_mongo(value)
        value
      end

      def changed_in_place?(original, new)
        original != new
      end

      def assert_valid_value; end

      def changed?(old, new, _new_value_before_type_cast)
        old.to_s != new.to_s
      end
    end
  end
end

class ObjectId
  extend MongoMapper::Extensions::ObjectId
end

class BSON::ObjectId
  alias_method :original_as_json, :as_json

  def as_json(options=nil)
    to_s
  end

  def to_json(options = nil)
    as_json.to_json
  end

  alias to_str to_s

  def original_to_json(*args)
    original_as_json.to_json(*args)
  end
end
