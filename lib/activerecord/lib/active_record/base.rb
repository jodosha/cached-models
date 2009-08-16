module ActiveRecord
  class Base
    @@associations_cache = nil
    cattr_reader :associations_cache

    protected
      def associations_cache
        self.class.associations_cache
      end
  end
end