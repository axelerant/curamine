require_dependency 'admin_controller'

module ExtendedAdminControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            before_filter :find_settings, :only => :projects

            alias_method_chain :projects, :extended
        end
    end

    module InstanceMethods

        def projects_with_extended
            projects_without_extended

            if params[:save] == '1'
                @list_settings.save
            end
        end

    private

        def find_settings
            @list_settings = UserListSetting.find_by_user_id_and_list(User.current.id, 'projects')
            @list_settings = UserListSetting.new(:user_id => User.current.id, :list => 'projects') unless @list_settings
            @list_settings.columns = params[:c] if params[:c]
        end

    end

end
