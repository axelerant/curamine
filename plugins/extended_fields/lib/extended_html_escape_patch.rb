module ExtendedHTMLEscapePatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :h, :extended
        end
    end

    module InstanceMethods

        def h_with_extended(s)
            s = s.to_s
            if s.html_safe?
                s
            else
                h_without_extended(s)
            end
        end

    end

end
