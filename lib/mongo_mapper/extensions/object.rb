# encoding: UTF-8
module MongoMapper
  module Extensions
    module Object
      extend ActiveSupport::Concern

      module ClassMethods
        def serialize(value)
          to_mongo(value)
        end

        def cast(value)
          value
        end

        def to_mongo(value)
          if value.respond_to?(:to_mongo)
            value.to_mongo
          end
          value
        end

        def from_mongo(value)
          value
        end
      end
    end
  end
end

class Object
  include MongoMapper::Extensions::Object
end
