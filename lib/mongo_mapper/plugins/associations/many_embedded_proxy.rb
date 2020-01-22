# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyEmbeddedProxy < EmbeddedCollection
        def replace(values)
          @_values = (values || []).compact.map do |v|
            v.is_a?(klass) ? v.to_mongo : klass.load(v, true).to_mongo
          end
          reset
        end

      private

        def find_target
          (@_values ||= []).map do |attrs|
            klass.load(attrs, true).tap do |child|
              assign_references(child)
            end
          end
        end
      end
    end
  end
end
