module ActiveRecord
  module Associations
    module ClassMethods
      # def has_many_with_association_cache(association_id, options = {}, &extension)
      #   has_many_without_association_cache(association_id, options, &extension)
      #   add_has_many_cache_callbacks if options[:cached]
      # end
      # alias_method_chain :has_many, :association_cache
      # 
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

      valid_keys_for_has_many_association << :cached
      valid_keys_for_belongs_to_association << :cached
    end
  end
end