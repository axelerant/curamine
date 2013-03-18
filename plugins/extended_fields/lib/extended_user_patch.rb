require_dependency 'user'

module ExtendedUserPatch

    def self.included(base)
        base.extend(ClassMethods)
    end

    module ClassMethods

        @@available_columns_cache = []

        @@available_columns = [
            ExtendedColumn.new(:login, :css_classes => 'username'),
            ExtendedColumn.new(:firstname),
            ExtendedColumn.new(:lastname),
            ExtendedColumn.new(:mail),
            ExtendedColumn.new(:admin,  :align => :center),
            ExtendedColumn.new(:status, :align => :center),
            ExtendedColumn.new(:language),
            ExtendedColumn.new(:auth_source),
            ExtendedColumn.new(:created_on,    :align => :center),
            ExtendedColumn.new(:updated_on,    :align => :center),
            ExtendedColumn.new(:last_login_on, :align => :center),
            ExtendedColumn.new(:full_name,
                               :caption => :label_full_name,
                               :value => lambda { |user| user.name }),
            ExtendedColumn.new(:assigned_issues,
                               :caption => :label_assigned_issues,
                               :value => lambda { |user| Issue.count(:conditions => [ "assigned_to_id = ?", user.id ]) },
                               :align => :center),
            ExtendedColumn.new(:assigned_open_issues,
                               :caption => :label_assigned_open_issues,
                               :value => lambda { |user| Issue.open.count(:conditions => [ "assigned_to_id = ?", user.id ]) },
                               :align => :center)
        ]

        def available_columns
            if @@available_columns_cache.any?
                @@available_columns_cache
            else
                @@available_columns_cache = @@available_columns.dup
                @@available_columns_cache += UserCustomField.all.collect{ |column| ExtendedCustomFieldColumn.new(column) }
            end
        end

        def add_available_column(column)
            @@available_columns << column if column.is_a?(ExtendedColumn)
            remove_class_variable(:@@available_columns_cache) if class_variable_defined?(:@@available_columns_cache)
        end

        def default_columns
            @@available_columns.select do |column|
                case column.name
                when :login, :firstname, :lastname, :mail, :admin, :created_on, :last_login_on
                    true
                else
                    false
                end
            end
        end

    end

end
