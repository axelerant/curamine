require_dependency 'users_controller'

module ExtendedUsersControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            before_filter :find_settings, :only => :index

            alias_method_chain :index, :extended
        end
    end

    module InstanceMethods

        def index_with_extended
            index_without_extended

            if params[:save] == '1'
                @list_settings.save
            end
        end

    private

        def find_settings
            @list_settings = UserListSetting.find_by_user_id_and_list(User.current.id, 'users')
            @list_settings = UserListSetting.new(:user_id => User.current.id, :list => 'users') unless @list_settings
            @list_settings.columns = params[:c] if params[:c]
        end

    end

end
