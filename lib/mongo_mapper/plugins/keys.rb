# encoding: UTF-8
require 'mongo_mapper/plugins/keys/key'
require 'mongo_mapper/plugins/keys/static'

module MongoMapper
  module Plugins
    module Keys
      extend ActiveSupport::Concern
      include ::ActiveModel::Attributes

      IS_RUBY_1_9 = method(:const_defined?).arity == 1

      included do
        extend ActiveSupport::DescendantsTracker

        key :_id, ObjectId, :default => lambda { BSON::ObjectId.new }
      end

      module ClassMethods
        include ::ActiveModel::Attributes::ClassMethods

        def inherited(descendant)
          descendant.instance_variable_set(:@keys, keys.dup)
          super
        end

        def keys
          _default_attributes
        end

        def dynamic_keys
          @dynamic_keys ||= Hash[*unaliased_keys.select {|k, v| v.dynamic? }.flatten(1)]
        end

        def defined_keys
          @defined_keys ||= Hash[*unaliased_keys.select {|k, v| !v.dynamic? }.flatten(1)]
        end

        def unaliased_keys
          @unaliased_keys ||= Hash[*keys.select {|k, v| k == v.name }.flatten(1)]
        end

        def dealias_keys(hash)
          out = {}
          hash.each do |k, v|
            name = dealias_key(k)
            out[name] = k.to_s.match(/^\$/) && v.is_a?(Hash) ? dealias_keys(v) : v
          end
          out
        end

        alias_method :dealias, :dealias_keys
        alias_method :unalias, :dealias_keys

        def dealias_key(name)
          keyname = name.to_s
          return name if @__opts.nil? || @__opts[keyname].nil?
          @__opts[keyname][:abbr] || @__opts[keyname][:alias] || @__opts[keyname][:field_name] || name
        end

        alias_method :persisted_name, :dealias_key
        alias_method :abbr, :dealias_key

        def alias_key(name)
          name = name.to_s
          return name if @__opts.nil?
          key_name = @__opts.detect { |k, v| v[:abbr].to_s == name || v[:alias].to_s == name || v[:field_name].to_s == name }
          return name if key_name.nil?
          key_name[0] || name
        end

        def key(name, type = String, **opts)
          name = name.to_s
          type = type_from_symbol(type)
          @__opts ||= {}
          @__opts[name] = opts.dup
          create_index(name) if opts[:index]
          create_validations_for(name, type)
          define_default_attribute(name, opts.fetch(:default, nil), type)
        end

        def key?(key)
          keys.key? key.to_s
        end

        def using_object_id?
          object_id_key?(:_id)
        end

        def object_id_keys
          @object_id_keys ||= _default_attributes.keys.select { |key| _default_attributes[key].type == ObjectId }.map(&:to_sym)
        end

        def object_id_key?(name)
          object_id_keys.include?(name.to_sym)
        end

        def to_mongo(instance)
          instance && instance.to_mongo
        end

        def from_mongo(value)
          value && (value.instance_of?(self) ? value : load(value))
        end

        # load is overridden in identity map to ensure same objects are loaded
        def load(attrs, with_cast = false)
          return nil if attrs.nil?
          begin
            attrs['_type'] ? attrs['_type'].constantize : self
          rescue NameError
            self
          end.allocate.initialize_from_database(attrs, with_cast)
        end

      private

        def type_from_symbol(type)
          return type unless type.is_a?(Symbol)
          {
            string: String,
            int: Integer,
            integer: Integer,
            float: Float,
            bool: Boolean,
            boolean: Boolean,
            array: Array,
            time: Time
          }[type]
        end

        def create_key_in_descendants(*args)
          descendants.each { |descendant| descendant.key(*args) }
        end

        def remove_key_in_descendants(name)
          descendants.each { |descendant| descendant.remove_key(name) }
        end

        def create_indexes_for(key)
          if key.options[:index] && !key.embeddable?
            warn "[DEPRECATION] :index option when defining key #{key.name.inspect} is deprecated. Put indexes in `db/indexes.rb`"
            ensure_index key.name
          end
        end

        def create_validations_for(key, type)
          options = @__opts[key]
          attribute = key.to_sym

          if options[:required]
            if type == Boolean
              validates_inclusion_of attribute, :in => [true, false]
            else
              validates_presence_of(attribute)
            end
          end

          if options[:unique]
            validates_uniqueness_of(attribute)
          end

          if options[:numeric]
            number_options = type == Integer ? {:only_integer => true} : {}
            validates_numericality_of(attribute, number_options)
          end

          if options[:format].present?
            validates_format_of(attribute, :with => options[:format])
          end

          if options[:in].present?
            validates_inclusion_of(attribute, :in => options[:in])
          end

          if options[:not_in].present?
            validates_exclusion_of(attribute, :in => options[:not_in])
          end

          if options[:length]
            length_options = case options[:length]
            when Integer
              {:minimum => 0, :maximum => options[:length]}
            when Range
              {:within => options[:length]}
            when Hash
              options[:length]
            end
            validates_length_of(attribute, length_options)
          end
        end

        def remove_validations_for(name)
          name = name.to_sym
          a_name = [name]

          _validators.reject!{ |key, _| key == name }
          remove_validate_callbacks a_name
        end

        def remove_validate_callbacks(a_name)
          chain = _validate_callbacks.dup.reject do |callback|
            f = callback.raw_filter
            f.respond_to?(:attributes) && f.attributes == a_name
          end
          reset_callbacks(:validate)
          chain.each do |callback|
            set_callback 'validate', callback.raw_filter
          end
        end
      end

      def initialize(attrs={})
        @_new = true
        @attributes = self.class._default_attributes.deep_dup
        self.attributes = attrs
        yield self if block_given?
      end

      def initialize_from_database(attrs={}, with_cast = false)
        @__type ||= {}
        @attributes = self.class._default_attributes.deep_dup
        attrs = attrs.with_indifferent_access
        embedded_associations.each do |assoc|
          next if attrs[assoc.name].nil?
          self.send("#{assoc.name.to_s}=", attrs[assoc.name])
          attrs.reject! { |name, _vals| name.to_s == assoc.name.to_s }
        end
        load_from_database(attrs, with_cast)
        self
      end

      def persisted?
        !new? && !destroyed?
      end

      def attributes=(attrs)
        return if attrs == nil || attrs.blank?

        attrs.each_pair do |key, value|
          if self.respond_to?("#{key}=")
            self.send("#{key}=", value)
          else
            write_key(key, value)
          end
        end
        attrs
      end

      def attributes
        @attributes.to_h
      end

      def to_mongo
        {}.tap do |hash|
          @attributes.keys.each do |k|
            # next unless assert_value_changed?(k)
            type = @attributes[k].type
            serialized_key = self.class.dealias_key(k)
            value = self[k]
            case
            when type == Array
              value = self[k].map { |elt| elt.class.to_mongo(elt) }
            when type == Hash
              value = {}.tap do |k_hash|
                self[k].each { |key, val| k_hash[key] = val.class.to_mongo(val) }
              end
            end
            hash[serialized_key] = @attributes[k].type.to_mongo(value)
          end

          embedded_associations.each do |assoc|
            if assoc.is_a?(Associations::OneAssociation)
              hash[assoc.name.to_s] = self.send(assoc.name).to_mongo
            else
              hash[assoc.name.to_s] = self.send(assoc.name).map(&:to_mongo)
            end
          end
        end
      end

      def assert_value_changed?(key)
        return true if key == '_id' && !respond_to?("#{key}_changed?")
        respond_to?("#{key}_changed?") && send("#{key}_changed?")
      end

      def assign(attrs={})
        warn "[DEPRECATION] #assign is deprecated, use #attributes="
        self.attributes = attrs
      end

      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end

      def update_attributes!(attrs={})
        self.attributes = attrs
        save!
      end

      def update_attribute(name, value)
        self.send(:"#{name}=", value)
        save(:validate => false)
      end

      def id
        self[:_id]
      end

      def id=(value)
        if self.class.using_object_id?
          value = ObjectId.to_mongo(value)
        end

        self[:_id] = value
      end

      def keys
        self.class.keys
      end

      def read_key(key_name)
        raise DocumentNotInitializedError.new(key_name) if @attributes.nil?
        @attributes[key_name.to_s].value
      end

      def [](key_name); read_key(key_name); end

      def attribute(key_name)
        read_key(key_name).tap do |val|
          if val.respond_to?(:_parent_document)
            val._parent_document = self
          end
        end
      end

      def []=(name, value)
        write_key(name, value)
      end

      def key_names
        @key_names ||= @attributes.keys
      end

      def non_embedded_keys
        @non_embedded_keys ||= keys.values.select { |key| !key.embeddable? }
      end

      def embedded_keys
        @embedded_keys ||= keys.values.select(&:embeddable?)
      end

    private

      def unalias_key(name)
        self.class.alias_key(name)
      end

      def load_from_database(attrs, with_cast)
        return if attrs == nil || attrs.blank?

        attrs.each do |key, value|
          key = self.class.alias_key(key)
          @__type[key] ||= type_from_value(key, value)
          internal_write_key key, @__type[key], value, with_cast
        end
      end

      # This exists to be patched over by plugins, while letting us still get to the undecorated
      # version of the method.
      def write_key(name, value)
        raise DocumentNotInitializedError.new(name) if @attributes.nil?

        # detect dynamic attribute
        @__type ||= {}
        @__type[name] ||= type_from_value(name, value)

        internal_write_key(name.to_s, @__type[name], value)
      end

      def internal_write_key(name, type, value, cast = true)
        unless @attributes.key?(name.to_s)
          dynamic_key(name, type)
        end

        if cast
          @attributes[name.to_s] = ::ActiveModel::Attribute.from_user(name, value, type, @attributes[name.to_s])
        else
          @attributes[name.to_s] = ::ActiveModel::Attribute.from_database(name, value, type)
        end
      end

      def dynamic_key(name, type)
        self.class.key(name, type, :__dynamic => true)
      end

      def attribute=(attribute_name, value)
        super.tap do |_|
          if value.respond_to?(:_parent_document=)
            value._parent_document = self
          end
        end
      end

      def type_from_value(name, val)
        attr = @attributes[name]
        type = attr.type

        # detect dynamic attribute
        if attr.class == ::ActiveModel::Attribute.null(name).class
          type = case val
          when ::BSON::ObjectId
            ObjectId
          when TrueClass, FalseClass
            Boolean
          else
            val.class
          end
        end

        type
      end
    end
  end
end
