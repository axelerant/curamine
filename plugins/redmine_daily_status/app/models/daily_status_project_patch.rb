
module DailyStatusProjectPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_many :daily_statuses
      has_one  :daily_status_setting

      def todays_status
        DailyStatus.todays_status_for self
      end
    end
  end
end

Project.send(:include, DailyStatusProjectPatch)
