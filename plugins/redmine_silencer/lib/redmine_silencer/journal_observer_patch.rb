module RedmineSilencer
  module JournalObserverPatch
    def self.included(base)
      base.class_eval do
        alias_method_chain :after_create, :silencer
      end
    end

    def after_create_with_silencer(journal)
      after_create_without_silencer(journal) if journal.notify?
    end
  end
end
