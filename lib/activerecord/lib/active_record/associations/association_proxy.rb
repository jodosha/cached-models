require 'set'

module ActiveRecord
  module Associations
    class AssociationProxy
      protected
        alias_method :active_record_set_belongs_to_association_for, :set_belongs_to_association_for
        def set_belongs_to_association_for_with_cache_expiration(record)
          reset_association_cache(record) if @reflection.options[:cached]
          active_record_set_belongs_to_association_for(record)
        end

      private
        def reset_association_cache(record)
          current_owner = current_owner(record)
          return unless current_owner
          current_owner.send(:cache_delete, @reflection)
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
