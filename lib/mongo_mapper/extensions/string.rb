# encoding: UTF-8
module MongoMapper
  module Extensions
    module String
      extend ActiveSupport::Concern

      module ClassMethods
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
          value && value.to_s
        end

        def from_mongo(value)
          value && value.to_s
        end

        def assert_valid_value(_); end

        def changed_in_place?(old, new)
          old != new && old.__id__ == new.__id__
        end

        def changed?(old, new, _new_value_before_type_cast)
          old != new
        end
      end

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
        value && value.to_s
      end

      def from_mongo(value)
        value && value.to_s
      end


      def _mongo_mapper_deep_copy_
        self.dup
      end
    end
  end
end

class String
  include MongoMapper::Extensions::String
end

class ActiveModel::Type::String
  include MongoMapper::Extensions::String
end
