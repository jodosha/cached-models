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
  end
end
