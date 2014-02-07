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


class DealImport
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include CSVImportable

  attr_accessor :file, :project, :quotes_type

  def klass
    Deal
  end

  def build_from_fcsv_row(row)
    ret = Hash[row.to_hash.map{ |k,v| [k.underscore.gsub(' ','_'), force_utf8(v)] }].delete_if{ |k,v| !klass.column_names.include?(k) }
    ret[:status_id] = DealStatus.where(:name => row['status']).first.try(:id) if row['status']
    ret[:category_id] = DealCategory.where(:name => row['category']).first.try(:id) if row['category']
    ret[:assigned_to_id] = User.find_by_login(row['assignee']).try(:id) unless row['assignee'].blank?
    ret[:price] = row['sum'].to_f if row['sum']
    if row['contact'].to_s.match(/^\#(\d+):/)
      ret[:contact_id] = Contact.find_by_id($1).try(:id)
    end
    ret
  end

end
