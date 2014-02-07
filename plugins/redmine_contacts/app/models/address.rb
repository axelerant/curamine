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

class Address < ActiveRecord::Base
  attr_reader :country

  belongs_to :addressable, :polymorphic => true

  scope :business, :conditions => {:address_type => "business"}
  scope :billing,  :conditions => {:address_type => "billing"}
  scope :shipping, :conditions => {:address_type => "shipping"}

  before_save :populate_full_address

  def country
    @country ||= l(:label_crm_countries)[country_code.to_sym].to_s unless country_code.blank?
  end

  def blank?
    %w(street1 street2 city region postcode country_code).all? { |attr| self.send(attr).blank? }
  end

  #----------------------------------------------------------------------------
  # Ensure blank address records don't get created. If we have a new record and
  #   address is empty then return true otherwise return false so that _destroy
  #   is processed (if applicable) and the record is removed.
  # Intended to be called as follows:
  #   accepts_nested_attributes_for :business_address, :allow_destroy => true, :reject_if => proc {|attributes| Address.reject_address(attributes)}
  def self.reject_address(attributes)
    exists = attributes['id'].present?
    empty = %w(street1 street2 city region postcode country_code full_address).map{|name| attributes[name].blank?}.all?
    attributes.merge!({:_destroy => 1}) if exists and empty
    return (!exists and empty)
  end

  def to_s
    %w(street1 street2 city postcode region country).map{ |attr| self.send(attr) }.select{|a| !a.blank? }.join(', ')
  end

  def post_address
    address_template = ContactsSetting.post_address_format
    address_template = address_template.gsub('%street1%', street1.to_s)
    address_template = address_template.gsub('%street2%', street2.to_s)
    address_template = address_template.gsub('%city%', city.to_s)
    address_template = address_template.gsub('%town%', city.to_s)
    address_template = address_template.gsub('%postcode%', postcode.to_s)
    address_template = address_template.gsub('%zip%', postcode.to_s)
    address_template = address_template.gsub('%region%', region.to_s)
    address_template = address_template.gsub('%state%', region.to_s)
    address_template = address_template.gsub('%country%', country.to_s)
    address_template.gsub(/\r\n?/, "\n").gsub(/^$\n/, '').gsub(/^[, ]+|[, ]+$|[,]{2,}/,'').gsub(/\s{2,}/, ' ').strip
  end

  private

  def populate_full_address
    self.full_address =  self.to_s
  end

end
