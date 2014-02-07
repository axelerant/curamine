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

class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :street1
      t.string :street2
      t.string :city
      t.string :region
      t.string :postcode
      t.string :country_code, :limit => 2
      t.string :full_address
      t.string :address_type, :limit => 16

      t.references :addressable, :polymorphic => true

      t.timestamps
    end
    add_index :addresses, [ :addressable_id, :addressable_type ]

    Contact.all.each do |asset|
      Address.create(:street1 => asset.attributes["address"].gsub(/\n/, ' '), :full_address => asset.attributes["address"], :address_type => "business", :addressable => asset) unless asset.attributes["address"].blank?
    end

    remove_column(:contacts, :address)
  end

end

