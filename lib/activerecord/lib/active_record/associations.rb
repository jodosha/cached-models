# FIXME load paths
require File.dirname(__FILE__) + '/associations/association_proxy'
require File.dirname(__FILE__) + '/associations/association_collection'
require File.dirname(__FILE__) + '/associations/has_many_association'

module ActiveRecord
  module Associations
    module ClassMethods
      def has_many(association_id, options = {}, &extension) #:nodoc:
        reflection = create_has_many_reflection(association_id, options, &extension)

        configure_dependency_for_has_many(reflection)

        add_multiple_associated_validation_callbacks(reflection.name) unless options[:validate] == false
        add_multiple_associated_save_callbacks(reflection.name)
        add_association_callbacks(reflection.name, reflection.options)

        if options[:through]
          collection_accessor_methods(reflection, HasManyThroughAssociation, options)
        else
          collection_accessor_methods(reflection, HasManyAssociation, options)
        end

        add_has_many_cache_callbacks if options[:cached]
      end

      alias_method :active_record_belongs_to, :belongs_to
      def belongs_to(association_id, options = {}) #:nodoc:
        active_record_belongs_to(association_id, options)
        add_belongs_to_cache_callbacks(association_id) if options[:cached]
      end

      def collection_reader_method(reflection, association_proxy_class, options)
        define_method(reflection.name) do |*params|
          ivar = "@#{reflection.name}"

          force_reload = params.first unless params.empty?

          association = if options[:cached]
            cache_read(reflection)
          else
            instance_variable_get(ivar) if instance_variable_defined?(ivar)
          end

          unless association.respond_to?(:loaded?)
            association = association_proxy_class.new(self, reflection)
            if options[:cached]
              cache_write(reflection, association)
            else
              instance_variable_set(ivar, association)
            end
          end

          if force_reload
            association.reload
            cache_write(reflection, association) if options[:cached]
          end

          association
        end

        method_name = "#{reflection.name.to_s.singularize}_ids"
        define_method(method_name) do
          if options[:cached]
            cache_fetch("#{cache_key}/#{method_name}", send("calculate_#{method_name}"))
          elsif send(reflection.name).loaded? || reflection.options[:finder_sql]
            send("calculate_#{method_name}")
          else
            send(reflection.name).all(:select => "#{reflection.quoted_table_name}.#{reflection.klass.primary_key}").map(&:id)
          end
        end

        define_method("calculate_#{method_name}") do
          send(reflection.name).map(&:id)
        end
      end

      def has_and_belongs_to_many(association_id, options = {}, &extension) #:nodoc:
        reflection = create_has_and_belongs_to_many_reflection(association_id, options, &extension)

        add_multiple_associated_validation_callbacks(reflection.name) unless options[:validate] == false
        add_multiple_associated_save_callbacks(reflection.name)
        collection_accessor_methods(reflection, HasAndBelongsToManyAssociation, options)

        # Don't use a before_destroy callback since users' before_destroy
        # callbacks will be executed after the association is wiped out.
        old_method = "destroy_without_habtm_shim_for_#{reflection.name}"
        class_eval <<-end_eval unless method_defined?(old_method)
          alias_method :#{old_method}, :destroy_without_callbacks
          def destroy_without_callbacks
            #{reflection.name}.clear
            #{old_method}
          end
        end_eval

        add_association_callbacks(reflection.name, options)
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

      def add_has_many_cache_callbacks
        method_name = :has_many_after_save_cache_expire
        return if respond_to? method_name

        define_method(method_name) do
          return unless self[:updated_at]

          self.class.reflections.each do |name, reflection|
            cache_delete(reflection) if reflection.options[:cached]
          end
        end
        after_save method_name
      end

      def add_belongs_to_cache_callbacks(reflection_name)
        after_save_method_name = "belongs_to_after_save_for_#{reflection_name}".to_sym
        after_destroy_method_name = "belongs_to_after_destroy_for_#{reflection_name}".to_sym
        return if respond_to? after_save_method_name

        define_method(after_save_method_name) do
          send(reflection_name).expire_cache_for(self.class.name)
        end

        alias_method after_destroy_method_name, after_save_method_name
        after_save after_save_method_name
        after_destroy after_destroy_method_name
      end
    end
  end
end
