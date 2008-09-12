module ActiveRecord
  class Base
    class << self
      def rails_cache
        ::Rails.cache
      end
    end

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
            rails_cache.delete("#{cache_key}/#{name}")
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
        cached_associations[reflection.name] = true
        rails_cache.fetch(reflection_cache_key(reflection)) { value }
      end
      
      def reflection_cache_key(reflection)
        "#{cache_key}/#{reflection.name}"
      end
      
      def cached_associations
        @cached_associations ||= {}
      end
  end
end