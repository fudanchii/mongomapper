# encoding: UTF-8
module MongoMapper
  module Extensions
    module Hash
      extend ActiveSupport::Concern

      module ClassMethods
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
          HashWithIndifferentAccess.new(value || {})
        end

        def from_mongo(value)
          HashWithIndifferentAccess.new(value || {})
        end

        def changed?(old, new, _new_before_type_cast)
          old != new
        end

        def changed_in_place?(old, new)
          false
        end
      end

      def _mongo_mapper_deep_copy_
        self.class.new.tap do |new_hash|
          each do |key, value|
            new_hash[key._mongo_mapper_deep_copy_] = value._mongo_mapper_deep_copy_
          end
        end
      end
    end
  end
end

class Hash
  include MongoMapper::Extensions::Hash
end
