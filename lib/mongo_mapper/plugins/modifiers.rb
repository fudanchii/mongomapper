# encoding: UTF-8
module MongoMapper
  module Plugins
    module Modifiers
      extend ActiveSupport::Concern

      module ClassMethods
        def increment(*args)
          modifier_update('$inc', args)
        end

        def decrement(*args)
          criteria, keys, options = criteria_and_keys_from_args(args)
          values, to_decrement = keys.values, {}
          keys.keys.each_with_index { |k, i| to_decrement[k] = -values[i].abs }
          collection.update_many(criteria, {'$inc' => to_decrement}, options || {})
        end

        def set(*args)
          criteria, updates, options = criteria_and_keys_from_args(args)
          updates.each do |key, value|
            updates[key] = keys[key.to_s].with_value_from_user(value).value if key?(key)
          end
          modifier_update('$set', [criteria, updates, options])
        end

        def unset(*args)
          if args[0].is_a?(Hash)
            criteria, keys = args.shift, args
            options = keys.last.is_a?(Hash) ? keys.pop : {}
          else
            keys, ids = args.partition { |arg| arg.is_a?(Symbol) }
            options = ids.last.is_a?(Hash) ? ids.pop : {}
            criteria = {:id => ids}
          end

          criteria = criteria_hash(criteria).to_hash
          updates = keys.inject({}) { |hash, key| hash[key] = 1; hash }
          modifier_update('$unset', [criteria, updates, options])
        end

        def push(*args)
          modifier_update('$push', args)
        end

        def push_all(*args)
          modifier_update('$pushAll', args)
        end

        def add_to_set(*args)
          modifier_update('$addToSet', args)
        end
        alias push_uniq add_to_set

        def pull(*args)
          modifier_update('$pull', args)
        end

        def pull_all(*args)
          modifier_update('$pullAll', args)
        end

        def pop(*args)
          modifier_update('$pop', args)
        end

        def find_one_and_update(args)
          args = args.dup
          args[:query]  = dealias_keys(args.delete :query)  if args.key? :query
          args[:update] = dealias_keys(args.delete :update) if args.key? :update
          collection.find_one_and_update(args[:query], args[:update], args)
        end
        alias_method :find_and_modify, :find_one_and_update

        def upsert(selector, updates, args = {})
          criteria = dealias_keys(selector)
          updates  = dealias_keys(updates)
          collection.update_one(criteria, updates, args.merge(upsert: true))
        end

      private

        def modifier_update(modifier, args)
          criteria, updates, options = criteria_and_keys_from_args(args)
          if options
            collection.update_many(criteria, {modifier => updates}, options)
          else
            collection.update_many(criteria, {modifier => updates})
          end
        end

        def criteria_and_keys_from_args(args)
          if args[0].is_a?(Hash)
            criteria = args[0]
            updates  = args[1]
            options  = args[2]
          else
            criteria, (updates, options) = args.partition { |a| !a.is_a?(Hash) }
            criteria = { :id => criteria }
          end
          upgrade_legacy_safe_usage!(options)
          updates = dealias_keys updates

          [criteria_hash(criteria).to_hash, updates, options]
        end

        def upgrade_legacy_safe_usage!(options)
          if options and options.key?(:safe)
            options.merge! Utils.get_safe_options(options)
            options.delete :safe
          end
        end
      end

      def unset(*args)
        self.class.unset({:_id => id}, *args)
      end

      def increment(hash, options=nil)
        self.class.increment({:_id => id}, hash, options)
      end

      def decrement(hash, options=nil)
        self.class.decrement({:_id => id}, hash, options)
      end

      def set(hash, options=nil)
        self.class.set({:_id => id}, hash, options)
      end

      def push(hash, options=nil)
        self.class.push({:_id => id}, hash, options)
      end

      def push_all(hash, options=nil)
        self.class.push_all({:_id => id}, hash, options)
      end

      def pull(hash, options=nil)
        self.class.pull({:_id => id}, hash, options)
      end

      def pull_all(hash, options=nil)
        self.class.pull_all({:_id => id}, hash, options)
      end

      def add_to_set(hash, options=nil)
        self.class.push_uniq({:_id => id}, hash, options)
      end
      alias push_uniq add_to_set

      def pop(hash, options=nil)
        self.class.pop({:_id => id}, hash, options)
      end
    end
  end
end
