require 'mongo_mapper/plugins/associations/nested_attributes'

module MongoMapper
  module Plugins
    module Document
      def mark_for_destruction
        @marked_for_destruction = true
      end

      def marked_for_destruction?
        @marked_for_destruction
      end
    end
  
    module EmbeddedDocument
      def mark_for_destruction
        @marked_for_destruction = true
      end

      def marked_for_destruction?
        @marked_for_destruction
      end
    end
  
  
    module Associations
      class Base
        def many?
          false
        end
        
        def one?
          false
        end
      end
      
      class ManyAssociation
        def many?
          true
        end
      end
      
      class BelongsToAssociation
        def one?
          true
        end
      end
      
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
      
      class BelongsToProxy
        def save_to_collection(options={})
          if @target 
            if @target.marked_for_destruction?
              @target.destroy
            else
              @target.save(options)
            end
          end
        end
      end
      
      class OneEmbeddedProxy
        def save_to_collection(options={})
          if @target 
            if @target.marked_for_destruction?
              @target = nil
            else
              @target.persist(options)
            end
          end
        end
      end
      
      class EmbeddedCollection
        def save_to_collection(options={})
          if @target
            @target.delete_if(&:marked_for_destruction?)
            @target.each{|doc| doc.persist(options)}
          end
        end
      end
          
    end  
  end
end

