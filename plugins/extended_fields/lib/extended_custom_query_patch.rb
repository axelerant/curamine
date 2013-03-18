require_dependency 'query'

module ExtendedCustomQueryPatch

    def self.included(base)
        if Redmine::VERSION::MAJOR < 2 || (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR == 0)
            base.send(:include, Redmine1InstanceMethods)
        else
            base.send(:include, Redmine2InstanceMethods)
        end
        #base.send(:include, CommonInstanceMethods)

        base.class_eval do
            unloadable

            alias_method_chain :add_custom_fields_filters, :extended
            #alias_method_chain :versions, :extended
        end
    end

    module Redmine2InstanceMethods

        def add_custom_fields_filters_with_extended(custom_fields, assoc = nil)
            add_custom_fields_filters_without_extended(custom_fields, assoc)

            custom_fields.select(&:is_filter?).each do |field|
                case field.field_format
                when "project"
                    options = { :type => :list_optional, :values => field.possible_values_options, :order => 20 }
                end
                filter_id = "cf_#{field.id}"
                filter_name = field.name
                if assoc.present?
                    filter_id = "#{assoc}.#{filter_id}"
                    filter_name = l("label_attribute_of_#{assoc}", :name => filter_name)
                end
                @available_filters[filter_id] = options.merge({ :name => filter_name, :format => field.field_format }) if options
            end
        end

    end

    module Redmine1InstanceMethods

        def add_custom_fields_filters_with_extended(custom_fields)
            add_custom_fields_filters_without_extended(custom_fields)

            custom_fields.select(&:is_filter?).each do |field|
                case field.field_format
                when "project"
                    options = { :type => :list_optional, :values => field.possible_values_options, :order => 20 }
                end

                options.merge!({:format => field.field_format}) if options && Redmine::VERSION::MAJOR == 2

                @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name }) if options
            end
        end

    end

    #module CommonInstanceMethods

        #def versions_with_extended(options = {})
            #options => {:conditions=>["effective_date BETWEEN ? AND ?", Sun, 30 Dec 2012, Sat, 02 Feb 2013]}
            #ExtendedDateField.find(options[:conditions][1], options[:conditions][2]) #Date
        #    versions_without_extended(options)
        #end

    #end

end
