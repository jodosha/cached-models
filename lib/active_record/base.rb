module ActiveRecord
  class Base
    @@rails_cache = nil
    mattr_reader :rails_cache

    protected
      def rails_cache
        self.class.rails_cache
      end
      
      # Expire the cache for the associations which contains the given class.
      #
      # Example:
      #   class Blog < ActiveRecord::Base
      #     has_many :posts, :cached => true
      #     has_many :recent_posts, :class_name => 'Post',
      #       :limit => 10, :order => 'id DESC', :cached => true
      #
      #     has_many :readers, :class_name => 'Person'
      #   end
      #
      # If one of the most recent posts will be updated, #expire_cache_for
      # will be invoked with the "Post" parameter, in order to expire the
      # cache for the first to associations.
      def expire_cache_for(class_name)
        self.class.reflections.each do |name, reflection|
          if reflection.options[:cached] and reflection.class_name == class_name
            cache_delete(reflection)
          end
        end
      end
      
      def cache_read(reflection)
        return unless cached_associations[reflection.name]
        rails_cache.read(reflection_cache_key(reflection))
      end

      def cache_write(reflection, value)
        cached_associations[reflection.name] = rails_cache.write(reflection_cache_key(reflection), value)
      end

      def cache_delete(reflection)
        return unless cached_associations[reflection.name]
        cached_associations[reflection.name] = !rails_cache.delete(reflection_cache_key(reflection))
      end

      def cache_fetch(reflection, value)
        reflection_name, key = extract_options_for_cache(reflection)
        cached_associations[reflection_name] = true
        rails_cache.fetch(key) { value }
      end
      
      def extract_options_for_cache(reflection)
        if reflection.is_a?(AssociationReflection)
          [ reflection.name, reflection_cache_key(reflection) ]
        else
          [ reflection.split('/').last, reflection ]
        end
      end
      
      def reflection_cache_key(reflection)
        "#{cache_key}/#{reflection.name}"
      end
      
      def cached_associations
        @cached_associations ||= {}
      end
  end
end