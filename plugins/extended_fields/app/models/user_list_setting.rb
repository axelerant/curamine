class UserListSetting < ActiveRecord::Base
    belongs_to :user

    SUPPORTED_LISTS = [ 'users', 'projects' ]

    serialize :columns, Array

    validates_presence_of :user, :list, :columns
    validates_uniqueness_of :user_id, :scope => :list
    validates_inclusion_of :list, :in => SUPPORTED_LISTS

    def initialize(attributes = nil)
        super
        self.columns ||= list_class.default_columns
    end

    def list_class
        case list
        when 'users'
            User
        when 'projects'
            Project
        end
    end

    def columns=(fields)
        if fields.is_a?(Array)
            write_attribute(:columns, fields.collect{ |field| field.is_a?(ExtendedColumn) ? field.name.to_sym : field.to_sym })
        else
            self.columns = [ fields ]
        end
        remove_instance_variable(:@extended_columns) if instance_variable_defined?(:@extended_columns)
    end

    def columns
        if @extended_columns
            @extended_columns
        else
            fields = read_attribute(:columns) || []
            fields = list_class.default_columns.collect{ |column| column.name } if fields.blank?

            available_columns = list_class.available_columns.inject({}) do |hash, column|
                hash[column.name] = column
                hash
            end

            @extended_columns = fields.inject([]) do |array, field|
                if available_columns[field.to_sym]
                    array << available_columns[field.to_sym]
                end
                array
            end
        end
    end

end
