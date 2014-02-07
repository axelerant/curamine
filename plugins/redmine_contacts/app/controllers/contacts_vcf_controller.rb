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

class ContactsVcfController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize

  def load
    begin
      vcard = Vcard::Vcard.decode(params[:contact_vcf]).first
      contact = {}
      contact[:first_name] = vcard.name.given
      contact[:middle_name] = vcard.name.additional
      contact[:last_name] = vcard.name.family
      contact[:phone] = vcard.telephones.join(', ')
      contact[:email] = vcard.emails.join(', ')
      contact[:website] = vcard.url.uri if vcard.url

      if vcard['ADR']
        contact[:address_attributes] = {}
        contact[:address_attributes][:street1] = vcard.address.street
        contact[:address_attributes][:city] = vcard.address.locality
        contact[:address_attributes][:postcode] = vcard.address.postalcode
        contact[:address_attributes][:region] = vcard.address.region
      end
      # contact[:street1] = vcard['ADR'].gsub('\\n', "\n") if vcard['ADR']
      contact[:birthday] = vcard.birthday
      contact[:background] = vcard.note
      contact[:company] = vcard.org.first if vcard.org
      contact[:job_title] = vcard.title

      respond_to do |format|
        format.html{  redirect_to :controller => "contacts", :action => "new", :project_id => @project, :contact => contact }
      end

    rescue Exception => e
      flash[:error] = e.message
      respond_to do |format|
        format.html{  redirect_to :back }
      end
    end

  end
end
