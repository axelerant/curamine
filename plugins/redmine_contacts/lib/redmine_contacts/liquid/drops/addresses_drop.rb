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

class AddressesDrop < Liquid::Drop

  def initialize(addresses)
    @addresses = addresses
  end

  def before_method(id)
    address = @addresses.where(:id => id).first || Address.new
    AddressDrop.new address
  end

  def all
    @all ||= @addresses.map do |address|
      AddressDrop.new address
    end
  end

  def visible
    @visible ||= @addresses.visible.map do |address|
      AddressDrop.new address
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class AddressDrop < Liquid::Drop

  delegate :id, :address_type, :street1, :street2, :city, :region, :postcode, :country_code, :country, :full_address, :post_address, :to => :@address

  def initialize(address)
    @address = address
  end

  private

  def helpers
    Rails.application.routes.url_helpers
  end

end
