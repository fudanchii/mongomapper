module MongoMapper
  module Plugins
    module DocAsType
      extend ActiveSupport::Concern

      module ClassMethods
        def changed?(old, new, _new_before_type_cast)
          old != new || old.changed?
        end

        def changed_in_place?(old, new)
          old == new && old.changed?
        end

        def serialize(value)
          value.to_mongo
        end

        def deserialize(value)
          from_mongo(value)
        end
      end
    end
  end
end

