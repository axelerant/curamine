module RedmineSilencer
  module JournalPatch
    def notify?
      @notify
    end

    def notify=(arg)
      @notify = !!arg
    end
  end
end
