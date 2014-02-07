# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require 'fileutils'

module RedmineContacts
  module Thumbnail
    extend Redmine::Utils::Shell
    include Redmine::Thumbnail

    CONVERT_BIN = (Redmine::Configuration['imagemagick_convert_command'] || 'convert').freeze

    # Generates a thumbnail for the source image to target
    def self.generate(source, target, size)
      return nil unless Redmine::Thumbnail.convert_available?
      unless File.exists?(target)
        directory = File.dirname(target)
        unless File.exists?(directory)
          FileUtils.mkdir_p directory
        end
        size_option = "#{size}x#{size}^"
        sharpen_option = "0.7x6"
        crop_option = "#{size}x#{size}"
        cmd = "#{shell_quote CONVERT_BIN} #{shell_quote source} -resize #{shell_quote size_option} -sharpen #{shell_quote sharpen_option} -gravity center -extent #{shell_quote crop_option} #{shell_quote target}"
        unless system(cmd)
          logger.error("Creating thumbnail failed (#{$?}):\nCommand: #{cmd}")
          return nil
        end
      end
      target
    end


  end
end
