require 'set'

module ActiveRecord
  module Associations
    class AssociationProxy
      protected
        def set_belongs_to_association_for(record)
          reset_association_cache(record) if @reflection.options[:cached]

          if @reflection.options[:as]
            record["#{@reflection.options[:as]}_id"]   = @owner.id unless @owner.new_record?
            record["#{@reflection.options[:as]}_type"] = @owner.class.base_class.name.to_s
          else
            record[@reflection.primary_key_name] = @owner.id unless @owner.new_record?
          end
        end

      private
        def reset_association_cache(record)
          current_owner = current_owner(record)
          return unless current_owner
          rails_cache.delete("#{current_owner.cache_key}/#{@reflection.name}")
        end

        def current_owner(record)
          current_owner_id, current_owner_type = if @reflection.options[:as]
            [ record["#{@reflection.options[:as]}_id"],
               record["#{@reflection.options[:as]}_type"] ]
          else
            [ record[@reflection.primary_key_name],
                @owner.class.base_class.name.to_s ]
          end

          return unless current_owner_id
          current_owner_type.constantize.find(current_owner_id)
        end
    end
  end
end
