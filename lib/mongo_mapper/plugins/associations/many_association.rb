# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyAssociation < Base

        def class_name
          @class_name ||= options[:class_name] || name.to_s.singularize.camelize
        end

        # hate this, need to revisit
        def proxy_class
          @proxy_class ||= if klass.embeddable?
            polymorphic? ? ManyEmbeddedPolymorphicProxy : ManyEmbeddedProxy
          else
            if polymorphic?
              ManyPolymorphicProxy
            elsif as?
              ManyDocumentsAsProxy
            elsif in_array?
              InArrayProxy
            else
              ManyDocumentsProxy
            end
          end
        end

        def setup(model)
          model.associations_module.module_eval <<-end_eval
            def #{name}
              get_proxy(associations[#{name.inspect}])
            end

            def #{name}=(value)
              associations[#{name.inspect}].tap do |assoc|
                value = value.compact.map do |val|
                  val[assoc.foreign_key] = self[:_id]
                  val
                end
                get_proxy(assoc).replace(value)
              end
              value
            end
          end_eval

          association = self
          options = self.options

          model.before_destroy do
            if !association.embeddable?
              case options[:dependent]
                when :destroy
                  self.get_proxy(association).destroy_all
                when :delete_all
                  self.get_proxy(association).delete_all
                when :nullify
                  self.get_proxy(association).nullify
              end
            end
          end
        end

        def autosave?
          options.fetch(:autosave, true)
        end
      end
    end
  end
end
