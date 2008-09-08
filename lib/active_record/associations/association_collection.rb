require 'set'

module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      # Add +records+ to this association.  Returns +self+ so method calls may be chained.  
      # Since << flattens its argument list and inserts each record, +push+ and +concat+ behave identically.
      def <<(*records)
        result = true
        load_target if @owner.new_record?

        @owner.transaction do
          flatten_deeper(records).each do |record|
            raise_on_type_mismatch(record)
            add_record_to_target_with_callbacks(record) do |r|
              result &&= insert_record(record) unless @owner.new_record?
            end
          end
        end

        if @reflection.options[:cached]
          rails_cache.write("#{@owner.cache_key}/#{@reflection.name}", self)
        end

        result && self
      end

      # Remove +records+ from this association.  Does not destroy +records+.
      def delete(*records)
        records = flatten_deeper(records)
        records.each { |record| raise_on_type_mismatch(record) }
        
        @owner.transaction do
          records.each { |record| callback(:before_remove, record) }
          
          old_records = records.reject {|r| r.new_record? }
          delete_records(old_records) if old_records.any?
          
          records.each do |record|
            @target.delete(record)
            callback(:after_remove, record)
          end
        end
      end

      # Removes all records from this association.  Returns +self+ so method calls may be chained.
      def clear
        return self if length.zero? # forces load_target if it hasn't happened already

        if @reflection.options[:dependent] && @reflection.options[:dependent] == :destroy
          destroy_all
        else          
          delete_all
        end

        if @reflection.options[:cached]
          rails_cache.write("#{@owner.cache_key}/#{@reflection.name}", self)
        end

        self
      end
    end
  end
end
