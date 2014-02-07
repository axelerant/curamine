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

module CSVImportable
  class << self; attr_accessor :klass end

  def persisted?
    false
  end

  def initialize(attributes = {})
    attributes.each{|name, value| send("#{name}=", value)}
  end

  def save
    if imported_instances.any? && imported_instances.map(&:valid?).all? && imported_instances.map{|c| c.new_record? ? true : (c.respond_to?('editable?') ? c.editable? : true)}.all?
      begin
        klass.transaction do
          imported_instances.each(&:save!)
        end
      rescue
        Rails.logger.info $!.message
        Rails.logger.info $!.backtrace.join("\n")
        return false
      end
      true
    else
      imported_instances.each_with_index do |instance, index|
        if !instance.new_record? && !instance.editable?
          errors.add :base, "Row #{index + 2}: Permission restricted for changing #{klass.name}"
        else
          instance.errors.full_messages.each do |message|
            errors.add :base, "Row #{index + 2}: #{message}"
          end
        end
      end
      false
    end
  end

  def imported_instances
    @imported_instances ||= load_imported_instances
  end

protected
  def force_utf8(v)
    if v.respond_to? :force_encoding then v.force_encoding('utf-8') else v end
  end

private
  def build_custom_fields
    custom_fields_attributes = {}
    klass.new.custom_field_values.each do |custom_field_value|
      custom_fields_attributes[custom_field_value.custom_field.id.to_s] = custom_field_value.custom_field.cast_value(row[custom_field_value.custom_field.name]).to_s
    end
    custom_fields_attributes
  end

  def load_imported_instances
    instance_rows = open_import_source
    klass.transaction do
      begin
        line_counter = 0
        instance_rows.map do |row|
          line_counter += 1
          instance = klass.find_by_id(row['#']) || klass.new
          instance.attributes = build_from_fcsv_row(row)
          if instance.respond_to?(:custom_field_values)
            instance.custom_field_values.each do |custom_field_value|
              custom_field_value.value = custom_field_value.custom_field.cast_value(row[custom_field_value.custom_field.name.underscore]).to_s
            end
          end

          instance.project = project if instance.respond_to?(:project=)
          puts instance.errors.full_messages unless instance.valid?
          instance
        end
      rescue
        Rails.logger.info $!.message
        Rails.logger.info $!.backtrace.join("\n")
        errors.add :base, I18n.t(:text_crm_error_on_line, :line => line_counter, :error => $!.message)
        []
      end
    end
  end

  def open_import_source
    begin
      content = file.read
      Rails.logger.info "quotes_type = #{quotes_type}"
      FCSV.parse(content, :headers => true, :header_converters => [:downcase], :encoding => 'utf-8', :col_sep => guess_separator(content), :quote_char => quotes_type)
    rescue Exception => e
      Rails.logger.info $!.message
      Rails.logger.info $!.backtrace.join("\n")
      errors.add :base, e.message
      []
    end
  end

  def guess_separator(content)
    first_line = content.split("\n").first
    commas = first_line.count(",")
    semicolons = first_line.count(";")
    commas > semicolons ? ',' : ';'
  end
end
