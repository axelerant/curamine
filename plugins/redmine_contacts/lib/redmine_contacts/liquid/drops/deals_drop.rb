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

class DealsDrop < Liquid::Drop

  def initialize(deals)
    @deals = deals
  end

  def before_method(id)
    deal = @deals.where(:id => id).first || Deal.new
    DealDrop.new deal
  end

  def all
    @all ||= @deals.map do |deal|
      DealDrop.new deal
    end
  end

  def visible
    @visible ||= @deals.visible.map do |deal|
      DealDrop.new deal
    end
  end

  def each(&block)
    all.each(&block)
  end

end


class DealDrop < Liquid::Drop

  delegate :id, :name, :created_on, :due_date, :price, :price_type, :currency, :background, :probability, :to => :@deal

  def initialize(deal)
    @deal = deal
  end

  def notes
    @deal.notes.map{|n| NotesDrop.new(n) }
  end

  def category
    @deal.category.name if @deal.category
  end

  def contact
    ContactDrop.new @deal.contact if @deal.contact
  end

  def status
    @deal.status.name if @deal.status
  end

  def custom_field_values
    @deal.custom_field_values
  end
end
