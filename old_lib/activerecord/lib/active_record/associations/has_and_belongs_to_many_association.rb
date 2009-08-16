module ActiveRecord
  module Associations
    class HasAndBelongsToManyAssociation < AssociationCollection #:nodoc:
      alias_method :active_record_insert_record, :insert_record
      def insert_record(record, force=true) #:nodoc:
        returning result = active_record_insert_record_without_cache_expiration(record, force) do
          @owner.send(:cache_delete, @reflection) if result && @reflection.options[:cached]
        end
      end
    end
  end
end
