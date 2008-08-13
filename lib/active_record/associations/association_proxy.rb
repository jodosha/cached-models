require 'set'

module ActiveRecord
  module Associations
    class AssociationProxy
      def observe
        observers << Observing::CacheObserver.new(@reflection.name, @owner)
      end

      def observers
        @observers ||= Set.new
      end

      def notify_observers
        observers.each { |observer| observer.reset_association }
      end

      protected
        def set_belongs_to_association_for(record)
          if @reflection.options[:cached] && current_owner_id(record)
            current_owner = @owner.class.find(current_owner_id(record))
            rails_cache.delete("#{current_owner.cache_key}/#{@reflection.name}")
            notify_observers
          end
          
          if @reflection.options[:as]
            record["#{@reflection.options[:as]}_id"]   = @owner.id unless @owner.new_record?
            record["#{@reflection.options[:as]}_type"] = @owner.class.base_class.name.to_s
          else
            record[@reflection.primary_key_name] = @owner.id unless @owner.new_record?
          end
        end

      private
        def current_owner_id(record)
          @reflection.options[:as] ? 
            record["#{@reflection.options[:as]}_id"] :
              record[@reflection.primary_key_name]
        end
    end
  end
end
