module ActiveRecord
  module Associations
    module ClassMethods
      valid_keys_for_has_many_association << :cached
      valid_keys_for_belongs_to_association << :cached
    end
  end
end