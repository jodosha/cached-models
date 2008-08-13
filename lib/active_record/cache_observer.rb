module ActiveRecord
  module Observing # :nodoc:
    class CacheObserver
      attr_reader :reflection_name, :owner

      def initialize(reflection_name, owner)
        @reflection_name, @owner = "@#{reflection_name}", owner
      end

      def reset_association
        owner.instance_variable_set(reflection_name, nil)
      end
    end
  end
end
