module MongoMapper

  class TooManyRecords < MongoMapper::Error
  end

  module Plugins
    module Associations
      module NestedAttributes
        extend ActiveSupport::Concern

        REJECT_ALL_BLANK_PROC = proc { |attributes| attributes.all? { |_, value| value.blank? } }
        
        included do
          # class_inheritable_accessor :nested_attributes_options, :instance_writer => false
          class_attribute :nested_attributes_options
          self.nested_attributes_options = {}
        end
        
        module Callbacks
          
          def save_associations
            associations.each do |key,association|
              # debugger if !association.many?
              # send(key).save! if nested_attributes_options.keys.include?(association.name) && !association.many?
              send(key).try(:save!) if nested_attributes_options.keys.include?(association.name) && !association.many? && !association.embeddable?
            end
          end
          
          def remove_embedded_associated_records
            associations.each do |key, association|
              next unless association.embeddable?
              self.send(key).delete_if(&:marked_for_destruction?)
            end
          end
        end

        module ClassMethods
          def accepts_nested_attributes_for(*attr_names)
            options = { :allow_destroy => false, :update_only => false }
            options.update(attr_names.extract_options!)
            options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
            options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank
            
            # Pull in callbacks and set them up
            include Callbacks
            before_validation :save_associations
            
            attr_names.each do |association_name|
              if association = associations[association_name]
                type = (association.many? ? :collection : :one_to_one)
                nested_attributes_options[association_name.to_sym] = options

                class_eval %{
                  if method_defined?(:#{association_name}_attributes=)
                    remove_method(:#{association_name}_attributes=)
                  end
                  def #{association_name}_attributes=(attributes)
                    assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
                  end
                }, __FILE__, __LINE__
              else
                raise ArgumentError, "No association found for name '#{association_name}'. Has it been defined yet?"
              end
            end
          end
        end

        private

        # Attribute hash keys that should not be assigned as normal attributes.
        # These hash keys are nested attributes implementation details.
        UNASSIGNABLE_KEYS = %w( id _destroy )

        def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
          options = nested_attributes_options[association_name]

          unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
            raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
          end

          limit = options[:limit].is_a?(Proc) ? options[:limit].call(self) : options[:limit]
          if limit && attributes_collection.size > limit
            raise TooManyRecords, "Maximum #{limit} records are allowed. Got #{attributes_collection.size} records instead."
          end

          if attributes_collection.is_a? Hash
            attributes_collection = attributes_collection.sort_by { |index, _| index.to_i }.map { |_, attributes| attributes }
          end

          attributes_collection.each do |attributes|
            attributes = attributes.with_indifferent_access

            if attributes['id'].blank?
              unless reject_new_record?(association_name, attributes)
                send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS)).tap do |new_rec|
                  new_rec._type = attributes['_type'] if attributes['_type']
                end
              end
            elsif existing_record = send(association_name).detect { |record| record.id.to_s == attributes['id'].to_s }
              assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
            else
              raise_nested_attributes_record_not_found(association_name, attributes['id'])
            end
          end
        end

        def assign_nested_attributes_for_one_to_one_association(association_name, attributes_collection)
          #require 'ruby_debug';debugger
          options = nested_attributes_options[association_name]
          association = associations[association_name]
          record = send(association_name)
          attributes_collection = attributes_collection.with_indifferent_access
          check_existing_record = (options[:update_only] || !attributes_collection['id'].blank?)

          if check_existing_record && record &&
              (options[:update_only] || record.id.to_s == attributes_collection['id'].to_s)
            
            assign_to_or_mark_for_destruction(record, attributes_collection, options[:allow_destroy]) unless call_reject_if(association_name, attributes_collection)

          elsif !attributes_collection['id'].blank?
            raise_nested_attributes_record_not_found(association_name, attributes_collection['id'])

          elsif !reject_new_record?(association_name, attributes_collection)
            if respond_to?(association_name)
              if association.one? && !association.embeddable?
                attributes_collection[self.class.name.foreign_key] = id
              end
              klass = association.klass
              create_method = klass.embeddable? ? :new : :create!
              send("#{association_name}=",klass.send(create_method, attributes_collection.except(*UNASSIGNABLE_KEYS)))

            else
              raise ArgumentError, "Cannot build association #{association_name}. Are you trying to build a polymorphic one-to-one association?"
            end
          end
        end

        # Updates a record with the +attributes+ or marks it for destruction if
        # +allow_destroy+ is +true+ and has_destroy_flag? returns +true+.
        def assign_to_or_mark_for_destruction(record, attributes, allow_destroy)
          if has_destroy_flag?(attributes) && allow_destroy
            record.mark_for_destruction
            # unless record.class.embeddable?
            #   record.mark_for_destruction
            # else
            #   record._parent_document.class.associations.each do |key, association|
            #     if association.klass.eql?(record.class)
            #       record._parent_document.send(key).delete_if {|q| q.id.to_s == record.id.to_s }
            #     end
            #   end
            # end
          else
            record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
          end
        end

        # Determines if a hash contains a truthy _destroy key.
        TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
        def has_destroy_flag?(hash)
          hash['_destroy'].present? && TRUE_VALUES.include?(hash['_destroy'])
        end

        # Determines if a new record should be build by checking for
        # has_destroy_flag? or if a <tt>:reject_if</tt> proc exists for this
        # association and evaluates to +true+.
        def reject_new_record?(association_name, attributes)
          has_destroy_flag?(attributes) || call_reject_if(association_name, attributes)
        end

        def call_reject_if(association_name, attributes)
          case callback = nested_attributes_options[association_name][:reject_if]
          when Symbol
            method(callback).arity == 0 ? send(callback) : send(callback, attributes)
          when Proc
            callback.call(attributes)
          end
        end

        def raise_nested_attributes_record_not_found(association_name, record_id)
          assoc = self.class.associations[association_name]
          raise DocumentNotFound, "Couldn't find #{assoc.klass.name} with ID=#{record_id} for #{self.class.name} with ID=#{id}"
        end
      end
    end
  end
end
