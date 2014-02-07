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

class ChangeDealsCurrencyType < ActiveRecord::Migration
  def up
    change_column :deals, :currency, :string
    Deal.where(:currency => '0').update_all(:currency => 'USD')
    Deal.where(:currency => '1').update_all(:currency => 'EUR')
    Deal.where(:currency => '2').update_all(:currency => 'GBP')
    Deal.where(:currency => '3').update_all(:currency => 'RUB')
    Deal.where(:currency => '4').update_all(:currency => 'JPY')
    Deal.where(:currency => '5').update_all(:currency => 'INR')
    Deal.where(:currency => '6').update_all(:currency => 'PLN')
  end

  def down
  end
end
