# encoding: UTF-8
module MongoMapper
  module Extensions
    module NilClass
      def serialize(value)
        value
      end

      def cast(value)
        value
      end

      def to_mongo(value)
        nil
      end

      def from_mongo(value)
        value
      end
    end
  end
end

class NilClass
  include MongoMapper::Extensions::NilClass

  def to_mongo
    nil
  end
end
