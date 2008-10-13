# FIXME load paths
require File.dirname(__FILE__) + '/associations/association_proxy'
require File.dirname(__FILE__) + '/associations/association_collection'
require File.dirname(__FILE__) + '/associations/has_many_association'

module ActiveRecord
  module Associations
    module ClassMethods
      # Adds the following methods for retrieval and query of collections of associated objects:
      # +collection+ is replaced with the symbol passed as the first argument, so
      # <tt>has_many :clients</tt> would add among others <tt>clients.empty?</tt>.
      # * <tt>collection(force_reload = false)</tt> - Returns an array of all the associated objects.
      #   An empty array is returned if none are found.
      # * <tt>collection<<(object, ...)</tt> - Adds one or more objects to the collection by setting their foreign keys to the collection's primary key.
      # * <tt>collection.delete(object, ...)</tt> - Removes one or more objects from the collection by setting their foreign keys to +NULL+.
      #   This will also destroy the objects if they're declared as +belongs_to+ and dependent on this model.
      # * <tt>collection=objects</tt> - Replaces the collections content by deleting and adding objects as appropriate.
      # * <tt>collection_singular_ids</tt> - Returns an array of the associated objects' ids
      # * <tt>collection_singular_ids=ids</tt> - Replace the collection with the objects identified by the primary keys in +ids+
      # * <tt>collection.clear</tt> - Removes every object from the collection. This destroys the associated objects if they
      #   are associated with <tt>:dependent => :destroy</tt>, deletes them directly from the database if <tt>:dependent => :delete_all</tt>,
      #   otherwise sets their foreign keys to +NULL+.
      # * <tt>collection.empty?</tt> - Returns +true+ if there are no associated objects.
      # * <tt>collection.size</tt> - Returns the number of associated objects.
      # * <tt>collection.find</tt> - Finds an associated object according to the same rules as Base.find.
      # * <tt>collection.build(attributes = {}, ...)</tt> - Returns one or more new objects of the collection type that have been instantiated
      #   with +attributes+ and linked to this object through a foreign key, but have not yet been saved. *Note:* This only works if an
      #   associated object already exists, not if it's +nil+!
      # * <tt>collection.create(attributes = {})</tt> - Returns a new object of the collection type that has been instantiated
      #   with +attributes+, linked to this object through a foreign key, and that has already been saved (if it passed the validation).
      #   *Note:* This only works if an associated object already exists, not if it's +nil+!
      #
      # Example: A Firm class declares <tt>has_many :clients</tt>, which will add:
      # * <tt>Firm#clients</tt> (similar to <tt>Clients.find :all, :conditions => "firm_id = #{id}"</tt>)
      # * <tt>Firm#clients<<</tt>
      # * <tt>Firm#clients.delete</tt>
      # * <tt>Firm#clients=</tt>
      # * <tt>Firm#client_ids</tt>
      # * <tt>Firm#client_ids=</tt>
      # * <tt>Firm#clients.clear</tt>
      # * <tt>Firm#clients.empty?</tt> (similar to <tt>firm.clients.size == 0</tt>)
      # * <tt>Firm#clients.size</tt> (similar to <tt>Client.count "firm_id = #{id}"</tt>)
      # * <tt>Firm#clients.find</tt> (similar to <tt>Client.find(id, :conditions => "firm_id = #{id}")</tt>)
      # * <tt>Firm#clients.build</tt> (similar to <tt>Client.new("firm_id" => id)</tt>)
      # * <tt>Firm#clients.create</tt> (similar to <tt>c = Client.new("firm_id" => id); c.save; c</tt>)
      # The declaration can also include an options hash to specialize the behavior of the association.
      #
      # Options are:
      # * <tt>:class_name</tt> - Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_many :products</tt> will by default be linked to the Product class, but
      #   if the real class name is SpecialProduct, you'll have to specify it with this option.
      # * <tt>:conditions</tt> - Specify the conditions that the associated objects must meet in order to be included as a +WHERE+
      #   SQL fragment, such as <tt>price > 5 AND name LIKE 'B%'</tt>.  Record creations from the association are scoped if a hash
      #   is used.  <tt>has_many :posts, :conditions => {:published => true}</tt> will create published posts with <tt>@blog.posts.create</tt>
      #   or <tt>@blog.posts.build</tt>.
      # * <tt>:order</tt> - Specify the order in which the associated objects are returned as an <tt>ORDER BY</tt> SQL fragment,
      #   such as <tt>last_name, first_name DESC</tt>.
      # * <tt>:foreign_key</tt> - Specify the foreign key used for the association. By default this is guessed to be the name
      #   of this class in lower-case and "_id" suffixed. So a Person class that makes a +has_many+ association will use "person_id"
      #   as the default <tt>:foreign_key</tt>.
      # * <tt>:dependent</tt> - If set to <tt>:destroy</tt> all the associated objects are destroyed
      #   alongside this object by calling their +destroy+ method.  If set to <tt>:delete_all</tt> all associated
      #   objects are deleted *without* calling their +destroy+ method.  If set to <tt>:nullify</tt> all associated
      #   objects' foreign keys are set to +NULL+ *without* calling their +save+ callbacks. *Warning:* This option is ignored when also using
      #   the <tt>:through</tt> option.
      # * <tt>:finder_sql</tt> - Specify a complete SQL statement to fetch the association. This is a good way to go for complex
      #   associations that depend on multiple tables. Note: When this option is used, +find_in_collection+ is _not_ added.
      # * <tt>:counter_sql</tt> - Specify a complete SQL statement to fetch the size of the association. If <tt>:finder_sql</tt> is
      #   specified but not <tt>:counter_sql</tt>, <tt>:counter_sql</tt> will be generated by replacing <tt>SELECT ... FROM</tt> with <tt>SELECT COUNT(*) FROM</tt>.
      # * <tt>:extend</tt> - Specify a named module for extending the proxy. See "Association extensions".
      # * <tt>:include</tt> - Specify second-order associations that should be eager loaded when the collection is loaded.
      # * <tt>:group</tt> - An attribute name by which the result should be grouped. Uses the <tt>GROUP BY</tt> SQL-clause.
      # * <tt>:limit</tt> - An integer determining the limit on the number of rows that should be returned.
      # * <tt>:offset</tt> - An integer determining the offset from where the rows should be fetched. So at 5, it would skip the first 4 rows.
      # * <tt>:select</tt> - By default, this is <tt>*</tt> as in <tt>SELECT * FROM</tt>, but can be changed if you, for example, want to do a join
      #   but not include the joined columns. Do not forget to include the primary and foreign keys, otherwise it will rise an error.
      # * <tt>:as</tt> - Specifies a polymorphic interface (See <tt>belongs_to</tt>).
      # * <tt>:through</tt> - Specifies a Join Model through which to perform the query.  Options for <tt>:class_name</tt> and <tt>:foreign_key</tt>
      #   are ignored, as the association uses the source reflection. You can only use a <tt>:through</tt> query through a <tt>belongs_to</tt>
      #   or <tt>has_many</tt> association on the join model.
      # * <tt>:source</tt> - Specifies the source association name used by <tt>has_many :through</tt> queries.  Only use it if the name cannot be
      #   inferred from the association.  <tt>has_many :subscribers, :through => :subscriptions</tt> will look for either <tt>:subscribers</tt> or
      #   <tt>:subscriber</tt> on Subscription, unless a <tt>:source</tt> is given.
      # * <tt>:source_type</tt> - Specifies type of the source association used by <tt>has_many :through</tt> queries where the source
      #   association is a polymorphic +belongs_to+.
      # * <tt>:uniq</tt> - If true, duplicates will be omitted from the collection. Useful in conjunction with <tt>:through</tt>.
      # * <tt>:readonly</tt> - If true, all the associated objects are readonly through the association.
      # * <tt>:cached</tt> - If true, all the associated objects will be cached.
      #
      # Option examples:
      #   has_many :comments, :order => "posted_on"
      #   has_many :comments, :include => :author
      #   has_many :people, :class_name => "Person", :conditions => "deleted = 0", :order => "name"
      #   has_many :tracks, :order => "position", :dependent => :destroy
      #   has_many :comments, :dependent => :nullify
      #   has_many :tags, :as => :taggable
      #   has_many :reports, :readonly => true
      #   has_many :posts, :cached => true
      #   has_many :subscribers, :through => :subscriptions, :source => :user
      #   has_many :subscribers, :class_name => "Person", :finder_sql =>
      #       'SELECT DISTINCT people.* ' +
      #       'FROM people p, post_subscriptions ps ' +
      #       'WHERE ps.post_id = #{id} AND ps.person_id = p.id ' +
      #       'ORDER BY p.first_name'
      def has_many(association_id, options = {}, &extension)
        reflection = create_has_many_reflection(association_id, options, &extension)

        configure_dependency_for_has_many(reflection)

        add_multiple_associated_save_callbacks(reflection.name)
        add_association_callbacks(reflection.name, reflection.options)

        if options[:through]
          collection_accessor_methods(reflection, HasManyThroughAssociation, options)
        else
          collection_accessor_methods(reflection, HasManyAssociation, options)
        end

        add_cache_callbacks if options[:cached]
      end

      # Adds the following methods for retrieval and query for a single associated object for which this object holds an id:
      # +association+ is replaced with the symbol passed as the first argument, so
      # <tt>belongs_to :author</tt> would add among others <tt>author.nil?</tt>.
      # * <tt>association(force_reload = false)</tt> - Returns the associated object. +nil+ is returned if none is found.
      # * <tt>association=(associate)</tt> - Assigns the associate object, extracts the primary key, and sets it as the foreign key.
      # * <tt>association.nil?</tt> - Returns +true+ if there is no associated object.
      # * <tt>build_association(attributes = {})</tt> - Returns a new object of the associated type that has been instantiated
      #   with +attributes+ and linked to this object through a foreign key, but has not yet been saved.
      # * <tt>create_association(attributes = {})</tt> - Returns a new object of the associated type that has been instantiated
      #   with +attributes+, linked to this object through a foreign key, and that has already been saved (if it passed the validation).
      #
      # Example: A Post class declares <tt>belongs_to :author</tt>, which will add:
      # * <tt>Post#author</tt> (similar to <tt>Author.find(author_id)</tt>)
      # * <tt>Post#author=(author)</tt> (similar to <tt>post.author_id = author.id</tt>)
      # * <tt>Post#author?</tt> (similar to <tt>post.author == some_author</tt>)
      # * <tt>Post#author.nil?</tt>
      # * <tt>Post#build_author</tt> (similar to <tt>post.author = Author.new</tt>)
      # * <tt>Post#create_author</tt> (similar to <tt>post.author = Author.new; post.author.save; post.author</tt>)
      # The declaration can also include an options hash to specialize the behavior of the association.
      #
      # Options are:
      # * <tt>:class_name</tt> - Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_one :author</tt> will by default be linked to the Author class, but
      #   if the real class name is Person, you'll have to specify it with this option.
      # * <tt>:conditions</tt> - Specify the conditions that the associated object must meet in order to be included as a +WHERE+
      #   SQL fragment, such as <tt>authorized = 1</tt>.
      # * <tt>:select</tt> - By default, this is <tt>*</tt> as in <tt>SELECT * FROM</tt>, but can be changed if, for example, you want to do a join
      #   but not include the joined columns. Do not forget to include the primary and foreign keys, otherwise it will raise an error.
      # * <tt>:foreign_key</tt> - Specify the foreign key used for the association. By default this is guessed to be the name
      #   of the association with an "_id" suffix. So a class that defines a <tt>belongs_to :person</tt> association will use
      #   "person_id" as the default <tt>:foreign_key</tt>. Similarly, <tt>belongs_to :favorite_person, :class_name => "Person"</tt>
      #   will use a foreign key of "favorite_person_id".
      # * <tt>:dependent</tt> - If set to <tt>:destroy</tt>, the associated object is destroyed when this object is. If set to
      #   <tt>:delete</tt>, the associated object is deleted *without* calling its destroy method. This option should not be specified when
      #   <tt>belongs_to</tt> is used in conjunction with a <tt>has_many</tt> relationship on another class because of the potential to leave
      #   orphaned records behind.
      # * <tt>:counter_cache</tt> - Caches the number of belonging objects on the associate class through the use of +increment_counter+
      #   and +decrement_counter+. The counter cache is incremented when an object of this class is created and decremented when it's
      #   destroyed. This requires that a column named <tt>#{table_name}_count</tt> (such as +comments_count+ for a belonging Comment class)
      #   is used on the associate class (such as a Post class). You can also specify a custom counter cache column by providing
      #   a column name instead of a +true+/+false+ value to this option (e.g., <tt>:counter_cache => :my_custom_counter</tt>.)
      #   When creating a counter cache column, the database statement or migration must specify a default value of <tt>0</tt>, failing to do 
      #   this results in a counter with +NULL+ value, which will never increment.
      #   Note: Specifying a counter cache will add it to that model's list of readonly attributes using +attr_readonly+.
      # * <tt>:include</tt> - Specify second-order associations that should be eager loaded when this object is loaded.
      # * <tt>:polymorphic</tt> - Specify this association is a polymorphic association by passing +true+.
      #   Note: If you've enabled the counter cache, then you may want to add the counter cache attribute
      #   to the +attr_readonly+ list in the associated classes (e.g. <tt>class Post; attr_readonly :comments_count; end</tt>).
      # * <tt>:readonly</tt> - If true, the associated object is readonly through the association.
      # * <tt>:validate</tt> - If false, don't validate the associated objects when saving the parent object. +false+ by default.
      #
      # Option examples:
      #   belongs_to :firm, :foreign_key => "client_of"
      #   belongs_to :author, :class_name => "Person", :foreign_key => "author_id"
      #   belongs_to :valid_coupon, :class_name => "Coupon", :foreign_key => "coupon_id",
      #              :conditions => 'discounts > #{payments_count}'
      #   belongs_to :attachable, :polymorphic => true
      #   belongs_to :project, :readonly => true
      #   belongs_to :post, :counter_cache => true
      #   belongs_to :blog, :cached => true
      def belongs_to(association_id, options = {})
        reflection = create_belongs_to_reflection(association_id, options)

        ivar = "@#{reflection.name}"

        if reflection.options[:polymorphic]
          association_accessor_methods(reflection, BelongsToPolymorphicAssociation)

          method_name = "polymorphic_belongs_to_before_save_for_#{reflection.name}".to_sym
          define_method(method_name) do
            association = instance_variable_get("#{ivar}") if instance_variable_defined?("#{ivar}")

            if association && association.target
              if association.new_record?
                association.save(true)
              end

              if association.updated?
                self["#{reflection.primary_key_name}"] = association.id
                self["#{reflection.options[:foreign_type]}"] = association.class.base_class.name.to_s
              end
            end
          end
          before_save method_name
        else
          association_accessor_methods(reflection, BelongsToAssociation)
          association_constructor_method(:build,  reflection, BelongsToAssociation)
          association_constructor_method(:create, reflection, BelongsToAssociation)

          method_name = "belongs_to_before_save_for_#{reflection.name}".to_sym
          define_method(method_name) do
            association = instance_variable_get("#{ivar}") if instance_variable_defined?("#{ivar}")

            if !association.nil?
              if association.new_record?
                association.save(true)
              end

              if association.updated?
                self["#{reflection.primary_key_name}"] = association.id
              end
            end
          end
          before_save method_name
        end

        # Create the callbacks to update counter cache
        if options[:counter_cache]
          cache_column = options[:counter_cache] == true ?
            "#{self.to_s.underscore.pluralize}_count" :
            options[:counter_cache]

          method_name = "belongs_to_counter_cache_after_create_for_#{reflection.name}".to_sym
          define_method(method_name) do
            association = send("#{reflection.name}")
            association.class.increment_counter("#{cache_column}", send("#{reflection.primary_key_name}")) unless association.nil?
          end
          after_create method_name

          method_name = "belongs_to_counter_cache_before_destroy_for_#{reflection.name}".to_sym
          define_method(method_name) do
            association = send("#{reflection.name}")
            association.class.decrement_counter("#{cache_column}", send("#{reflection.primary_key_name}")) unless association.nil?
          end
          before_destroy method_name

          module_eval(
            "#{reflection.class_name}.send(:attr_readonly,\"#{cache_column}\".intern) if defined?(#{reflection.class_name}) && #{reflection.class_name}.respond_to?(:attr_readonly)"
          )
        end

        if options[:cached]
          method_name = "belongs_to_after_save_for_#{reflection.name}".to_sym
          define_method(method_name) do
            send(reflection.name).expire_cache_for(self.class.name)
          end
          after_save method_name
        end

        add_single_associated_validation_callbacks(reflection.name) if options[:validate] == true

        configure_dependency_for_belongs_to(reflection)
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
            instance_variable_set(ivar, association)
          end

          if force_reload
            association.reload
            cache_delete(reflection) if options[:cached]
          end

          if options[:cached]
            cache_fetch(reflection, association)
          else
            association
          end
        end

        method_name = "#{reflection.name.to_s.singularize}_ids"
        define_method(method_name) do
          if options[:cached]
            cache_fetch("#{cache_key}/#{method_name}", send("calculate_#{method_name}"))
          else
            send("calculate_#{method_name}")
          end
        end
        
        define_method("calculate_#{method_name}") do
          send(reflection.name).map { |record| record.id }
        end
      end

      def has_and_belongs_to_many(association_id, options = {}, &extension)
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

      def create_has_many_reflection(association_id, options, &extension)
        options.assert_valid_keys(
          :class_name, :table_name, :foreign_key, :primary_key,
          :dependent,
          :select, :conditions, :include, :order, :group, :limit, :offset,
          :as, :through, :source, :source_type,
          :uniq,
          :finder_sql, :counter_sql,
          :before_add, :after_add, :before_remove, :after_remove,
          :extend, :readonly,
          :validate, :accessible,
          :cached
        )

        options[:extend] = create_extension_modules(association_id, extension, options[:extend])

        create_reflection(:has_many, association_id, options, self)
      end

      def create_belongs_to_reflection(association_id, options)
        options.assert_valid_keys(
          :class_name, :foreign_key, :foreign_type, :remote, :select, :conditions, :include, :dependent,
          :counter_cache, :extend, :polymorphic, :readonly, :validate, :cached
        )

        reflection = create_reflection(:belongs_to, association_id, options, self)

        if options[:polymorphic]
          reflection.options[:foreign_type] ||= reflection.class_name.underscore + "_type"
        end

        reflection
      end

      def add_cache_callbacks
        method_name = :after_save_cache_expire
        return if respond_to? method_name

        define_method(method_name) do
          return unless self[:updated_at]

          self.class.reflections.each do |name, reflection|
            cache_delete(reflection) if reflection.options[:cached]
          end
        end
        after_save method_name
      end
    end
  end
end
