module ActiveRecord
  module Associations
    class HasAndBelongsToManyAssociation < AssociationCollection #:nodoc:
      def insert_record(record, force=true) #:nodoc:
        if record.new_record?
          if force
            record.save!
          else
            return false unless record.save
          end
        end

        if @reflection.options[:insert_sql]
          @owner.connection.insert(interpolate_sql(@reflection.options[:insert_sql], record))
        else
          columns = @owner.connection.columns(@reflection.options[:join_table], "#{@reflection.options[:join_table]} Columns")

          attributes = columns.inject({}) do |attrs, column|
            case column.name.to_s
              when @reflection.primary_key_name.to_s
                attrs[column.name] = owner_quoted_id
              when @reflection.association_foreign_key.to_s
                attrs[column.name] = record.quoted_id
              else
                if record.has_attribute?(column.name)
                  value = @owner.send(:quote_value, record[column.name], column)
                  attrs[column.name] = value unless value.nil?
                end
            end
            attrs
          end

          sql =
            "INSERT INTO #{@owner.connection.quote_table_name @reflection.options[:join_table]} (#{@owner.send(:quoted_column_names, attributes).join(', ')}) " +
            "VALUES (#{attributes.values.join(', ')})"

          @owner.connection.insert(sql)
        end

        @owner.send(:cache_delete, @reflection) if @reflection.options[:cached]

        return true
      end
    end
  end
end
