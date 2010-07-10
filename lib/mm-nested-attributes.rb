require 'mongo_mapper/plugins/associations/nested_attributes'

module MongoMapper
  module Plugins
    module Document
      module InstanceMethods
        def mark_for_destruction
          @marked_for_destruction = true
        end

        def marked_for_destruction?
          @marked_for_destruction
        end
      end
    end
  end
end

module MongoMapper
  module Plugins
    module Associations
      class ManyDocumentsProxy
        def save_to_collection_with_delete(options={})
          if @target
            to_delete = @target.delete_if { |doc| doc.marked_for_destruction? }
            to_delete.each { |doc| doc.destroy }
          end
          save_to_collection_without_delete(options)
        end

        alias :save_to_collection_without_delete :save_to_collection
        alias :save_to_collection :save_to_collection_with_delete
      end
    end
  end
end
