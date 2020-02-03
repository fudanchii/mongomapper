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

      def _mongo_mapper_deep_copy_
        dup
      end
    end
  end
end

class Object
  include MongoMapper::Extensions::Object

  private

  def method_missing(name, *args, &block)
    if name.to_sym != :to_mongo
      return super
    end

    self.class.to_mongo(self)
  end
end
