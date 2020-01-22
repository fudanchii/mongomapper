# encoding: UTF-8
module MongoMapper
  module Extensions
    module Array
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
          value = value.respond_to?(:lines) ? value.lines : value
          value.to_a
        end

        def from_mongo(value)
          value || []
        end

        def changed_in_place?(old, new)
          false
        end

        def changed?(old, new, _new_before_type_casat)
          old != new
        end
      end

      def _mongo_mapper_deep_copy_
        map { |value| value._mongo_mapper_deep_copy_ }
      end
    end
  end
end

class Array
  include MongoMapper::Extensions::Array
end
