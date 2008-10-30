require 'set'

module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      def find(*args)
        options       = args.extract_options!
        expects_array = args.first.kind_of?(Array)
        args          = args.flatten.compact.uniq

        if @reflection.options[:cached] && !args.first.is_a?(Symbol)
          result = self.select { |record| args.map(&:to_i).include? record.id }
          return expects_array ? result : result.first
        end

        # If using a custom finder_sql, scan the entire collection.
        if @reflection.options[:finder_sql]
          ids = args.flatten.compact.uniq.map(&:to_i)
          if ids.size == 1
            id = ids.first
            record = load_target.detect { |r| id == r.id }
            expects_array ? [ record ] : record
          else
            load_target.select { |r| ids.include?(r.id) }
          end
        else
          conditions = "#{@finder_sql}"
          if sanitized_conditions = sanitize_sql(options[:conditions])
            conditions << " AND (#{sanitized_conditions})"
          end

          options[:conditions] = conditions

          if options[:order] && @reflection.options[:order]
            options[:order] = "#{options[:order]}, #{@reflection.options[:order]}"
          elsif @reflection.options[:order]
            options[:order] = @reflection.options[:order]
          end

          # Build options specific to association
          construct_find_options!(options)

          merge_options_from_reflection!(options)

          # Pass through args exactly as we received them.
          args << options
          @reflection.klass.find(*args)
        end
      end

      # Add +records+ to this association.  Returns +self+ so method calls may be chained.  
      # Since << flattens its argument list and inserts each record, +push+ and +concat+ behave identically.
      def <<(*records)
        result = true
        load_target if @owner.new_record?

        transaction do
          flatten_deeper(records).each do |record|
            raise_on_type_mismatch(record)
            add_record_to_target_with_callbacks(record) do |r|
              result &&= insert_record(record) unless @owner.new_record?
            end
          end
        end

        @owner.send(:cache_write, @reflection, self) if @reflection.options[:cached]

        result && self
      end

      # Removes +records+ from this association calling +before_remove+ and
      # +after_remove+ callbacks.
      #
      # This method is abstract in the sense that +delete_records+ has to be
      # provided by descendants. Note this method does not imply the records
      # are actually removed from the database, that depends precisely on
      # +delete_records+. They are in any case removed from the collection.
      def delete(*records)
        records = flatten_deeper(records)
        records.each { |record| raise_on_type_mismatch(record) }

        transaction do
          records.each { |record| callback(:before_remove, record) }

          old_records = records.reject {|r| r.new_record? }
          delete_records(old_records) if old_records.any?

          records.each do |record|
            @target.delete(record)
            callback(:after_remove, record)
          end
        end

        @owner.send(:cache_write, @reflection, self) if @reflection.options[:cached]
      end

      # Removes all records from this association.  Returns +self+ so method calls may be chained.
      def clear
        return self if length.zero? # forces load_target if it hasn't happened already

        if @reflection.options[:dependent] && @reflection.options[:dependent] == :destroy
          destroy_all
        else 
          delete_all
        end

        @owner.send(:cache_write, @reflection, self) if @reflection.options[:cached]

        self
      end

      # Returns the size of the collection by executing a SELECT COUNT(*)
      # query if the collection hasn't been loaded, and calling
      # <tt>collection.size</tt> if it has.
      #
      # If the collection has been already loaded +size+ and +length+ are
      # equivalent. If not and you are going to need the records anyway
      # +length+ will take one less query. Otherwise +size+ is more efficient.
      #
      # This method is abstract in the sense that it relies on
      # +count_records+, which is a method descendants have to provide.
      def size
        if @reflection.options[:cached]
          returning result = self.to_ary do
            @reflection.options[:uniq] ? result.uniq.size : result.size
          end
        end

        if @owner.new_record? || (loaded? && !@reflection.options[:uniq])
          @target.size
        elsif !loaded? && @reflection.options[:group]
          load_target.size
        elsif !loaded? && !@reflection.options[:uniq] && @target.is_a?(Array)
          unsaved_records = @target.select { |r| r.new_record? }
          unsaved_records.size + count_records
        else
          count_records
        end
      end
    end
  end
end
