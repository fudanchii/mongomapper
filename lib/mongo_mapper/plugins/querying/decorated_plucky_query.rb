# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      Methods = Plucky::Methods + [:delete, :delete_all, :destroy, :destroy_all, :find!]

      class DecoratedPluckyQuery < ::Plucky::Query
        include DynamicQuerying::ClassMethods

        def where(predicates)
          super(
            {}.tap do |arg|
              predicates.each do |k, v|
                type = keys[k.to_s].type
                arg[k] = type.respond_to?(:to_mongo) ? transform_to_mongo(type, v) : v
              end
            end
          )
        end

        def delete(*ids)
          where(:_id => ids.flatten).remove
        end

        def delete_all(options = {})
          where(options).remove
        end

        def destroy(*ids)
          [find!(*ids.flatten.compact.uniq)].flatten.each { |doc| doc.destroy }
        end

        def destroy_all(options={})
          find_each(options) { |document| document.destroy }
        end

        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def criteria_hash
          @model.dealias_keys super
        end

        def options_hash
          super.tap do |options|
            case options[:projection]
            when Hash
              options[:projection] = @model.dealias options[:projection]
            when Array
              options[:projection] = options[:projection].map do |field|
                key = keys[field.to_s]
                key && key.abbr || field
              end
            end
          end
        end

        def find!(*ids)
          ids = Array(ids).flatten.uniq
          raise DocumentNotFound, "Couldn't find without an ID" if ids.size == 0

          find(*ids).tap do |result|
            if result.nil? || ids.size != Array(result).size
              raise DocumentNotFound, "Couldn't find all of the ids (#{ids.join(',')}). Found #{Array(result).size}, but was expecting #{ids.size}"
            end
          end
        end

      private

        def transform_to_mongo(type, value)
          if value.is_a?(Array)
            return array_to_mongo(type, value)
          end

          if value.is_a?(Hash)
            return hash_to_mongo(type, value)
          end

          type.to_mongo(value)
        end

        def array_to_mongo(type, value)
          value.map do |ival|
            if ival.is_a?(Array)
              array_to_mongo(type, ival)
            elsif ival.is_a?(Hash)
              hash_to_mongo(type, ival)
            else
              type.to_mongo(ival)
            end
          end
        end

        def hash_to_mongo(type, value)
          value.each do |k, v|
            value[k] = if v.is_a?(Array)
                         array_to_mongo(v)
                       elsif v.is_a?(Hash)
                         hash_to_mongo(v)
                       else
                         type.to_mongo(v)
                       end
          end
        end

        def method_missing(method, *args, &block)
          return super unless model.respond_to?(method)

          result = model.with_scope(criteria_hash) do
            model.send(method, *args, &block)
          end

          case result
          when Plucky::Query
            merge(result)
          else
            result
          end
        end
      end
    end
  end
end
