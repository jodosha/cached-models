module ActiveRecord
  module Associations
    module ClassMethods
      def has_many(association_id, options = {}, &extension) #:nodoc:
        reflection = create_has_many_reflection(association_id, options, &extension)

        configure_dependency_for_has_many(reflection)
        add_association_callbacks(reflection.name, reflection.options)

        if options[:through]
          collection_accessor_methods(reflection, HasManyThroughAssociation, options)
        else
          collection_accessor_methods(reflection, HasManyAssociation, options)
        end

        # add_has_many_cache_callbacks if options[:cached]
      end

      # def add_has_many_cache_callbacks
      #   method_name = :has_many_after_save_cache_expire
      #   return if respond_to? method_name
      # 
      #   define_method(method_name) do
      #     return unless self[:updated_at]
      # 
      #     self.class.reflections.each do |name, reflection|
      #       expire_cache_for(reflection.class_name)
      #     end
      #   end
      #   after_save method_name
      # end

      def collection_reader_method(reflection, association_proxy_class, options)
        define_method(reflection.name) do |*params|
          force_reload = params.first unless params.empty?

          association = if options[:cached]
            cache_read(reflection)
          else
            association_instance_get(reflection.name)
          end

          unless association
            association = association_proxy_class.new(self, reflection)
            if options[:cached]
              cache_write(reflection, association)
            else
              association_instance_set(reflection.name, association)
            end
          end

          if force_reload
            association.reload
            cache_write(reflection, association) if options[:cached]
          end

          association
        end

        define_method("#{reflection.name.to_s.singularize}_ids") do
          if send(reflection.name).loaded? || reflection.options[:finder_sql]
            send(reflection.name).map(&:id)
          else
            send(reflection.name).all(:select => "#{reflection.quoted_table_name}.#{reflection.klass.primary_key}").map(&:id)
          end
        end
      end

      def collection_accessor_methods(reflection, association_proxy_class, options, writer = true)
        collection_reader_method(reflection, association_proxy_class, options)

        if writer
          define_method("#{reflection.name}=") do |new_value|
            # Loads proxy class instance (defined in collection_reader_method) if not already loaded
            association = send(reflection.name)
            association.replace(new_value)
            cache_write(reflection, association) if options[:cached]
            association
          end

          define_method("#{reflection.name.to_s.singularize}_ids=") do |new_value|
            ids = (new_value || []).reject { |nid| nid.blank? }
            send("#{reflection.name}=", reflection.class_name.constantize.find(ids))
          end
        end
      end

      valid_keys_for_has_many_association << :cached
      valid_keys_for_belongs_to_association << :cached
    end
  end
end