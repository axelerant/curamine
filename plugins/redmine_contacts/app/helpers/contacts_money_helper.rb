# encoding: utf-8
#
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

require 'money'

module ContactsMoneyHelper

  def object_price(obj, price_field = :price)
    price_to_currency(obj.try(price_field), obj.currency, :symbol => true).to_s if obj.respond_to?(:currency)
  end

  def prices_collection_by_currency(prices_collection, options={})
    return [] if prices_collection.blank?
    prices_collection.collect{|c| content_tag(:span, price_to_currency(c[1], c[0], :symbol => true), :style => "white-space: nowrap;") unless c[1] == 0 && options[:hide_zeros]}.compact
  end

  def deal_currency_icon(currency)
    case currency.to_s.upcase
    when 'EUR'
      "icon-money-euro"
    when 'GBP'
      "icon-money-pound"
    when 'JPY'
      "icon-money-yen"
    else
      "icon-money-dollar"
    end
  end

  def collection_for_currencies_select(default_currency = ContactsSetting.default_currency)
    major_currencies_collection(default_currency)
  end

  def major_currencies_collection(default_currency)
    currencies = []
    currencies << default_currency.to_s unless default_currency.blank?
    currencies |= ContactsSetting.major_currencies
    currencies.map do |c|
      currency = Money::Currency.find(c)
      ["#{currency.name} (#{currency.symbol})", currency.iso_code] if currency
    end.compact.uniq
  end

  def all_currencies
    Money::Currency.table.inject([]) do |array, (id, attributes)|
      array ||= []
      array << ["#{attributes[:name]}" + (attributes[:symbol].blank? ? "" : " (#{attributes[:symbol]})"), attributes[:iso_code]]
      array
    end.sort{|x, y| x[0] <=> y[0]}
  end

  def price_to_currency(price, currency, options={})
    return '' if price.blank?
    options[:decimal_mark] = ContactsSetting.decimal_separator unless options[:decimal_mark]
    options[:thousands_separator] = ContactsSetting.thousands_delimiter unless options[:thousands_separator]
    Money.from_float(price.to_f, currency).format(options) rescue ActionController::Base.helpers.number_with_delimiter(price.to_f, :separator => ContactsSetting.decimal_separator, :delimiter => ContactsSetting.thousands_delimiter, :precision => 2)
  end

end
