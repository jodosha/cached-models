module ActiveRecord
  class Base
    @@associations_cache = nil
    cattr_reader :associations_cache

    protected
      def associations_cache
        self.class.associations_cache
      end

      def cache_write(reflection, value)
        associations_cache.write association_cache_key(reflection), value
      end

      def cache_delete(reflection)
        associations_cache.delete association_cache_key(reflection)
      end

      def association_cache_key(reflection)
        "#{cache_key}/#{reflection.name}"
      end
  end
end