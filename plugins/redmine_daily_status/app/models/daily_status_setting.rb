class DailyStatusSetting < ActiveRecord::Base
  unloadable

  belongs_to :project
  acts_as_watchable DailyStatusSetting

  # TODO : find out hook when a project adds the module Daily Status from its settings
end
