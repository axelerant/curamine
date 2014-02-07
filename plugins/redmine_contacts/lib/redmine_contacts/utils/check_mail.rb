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

require 'net/imap'
require 'net/pop'
require 'openssl'
require 'timeout'


module RedmineContacts
  module Mailer
    class << self

      def check_imap(mailer, imap_options={}, options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX'

        Timeout::timeout(15) do
          @imap = Net::IMAP.new(host, port, ssl)
          @imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        end

        @imap.select(folder)
        msg_count = 0

        @imap.uid_search(['NOT', 'SEEN']).each do |uid|
          msg = @imap.uid_fetch(uid,'RFC822')[0].attr['RFC822']
          logger.info "ContactsMailHandler: Receiving message #{uid}" if logger && logger.info?
          msg_count += 1

          if mailer.receive(msg, options)
            logger.info "ContactsMailHandler: Message #{uid} successfully received" if logger && logger.info?
            if imap_options[:move_on_success] && imap_options[:move_on_success] != folder
                @imap.uid_copy(uid, imap_options[:move_on_success])
            end
            @imap.uid_store(uid, "+FLAGS", [:Seen, :Deleted])
          else
            logger.info "ContactsMailHandler: Message #{uid} can not be processed" if logger && logger.info?
            @imap.uid_store(uid, "+FLAGS", [:Seen])
            if imap_options[:move_on_failure]
              @imap.uid_copy(uid, imap_options[:move_on_failure])
              @imap.uid_store(uid, "+FLAGS", [:Deleted])
            end
          end
        end
        @imap.expunge
        msg_count
      ensure
        if defined?(@imap) && @imap && !@imap.disconnected?
          @imap.disconnect
        end
      end

      def check_pop3(mailer, pop_options={}, options={})

        host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        delete_unprocessed = (pop_options[:delete_unprocessed].to_s == '1')

        pop = Net::POP3.APOP(apop).new(host,port)
        pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if pop_options[:ssl]
        logger.info "ContactsMailHandler: Connecting to #{host}..." if logger && logger.info?
        msg_count = 0
        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          if pop_session.mails.empty?
            logger.info "ContactsMailHandler: No email to process" if logger && logger.info?
          else
            logger.info "ContactsMailHandler: #{pop_session.mails.size} email(s) to process..." if logger && logger.info?
            pop_session.each_mail do |msg|
              msg_count += 1
              message = msg.pop
              uid = (message =~ /^Message-ID: (.*)/ ? $1 : '').strip
              if mailer.receive(message, options)
                msg.delete
                logger.info "--> ContactsMailHandler: Message #{uid} processed and deleted from the server" if logger && logger.info?
              else
                if delete_unprocessed
                  msg.delete
                  logger.info "--> ContactsMailHandler: Message #{uid} NOT processed and deleted from the server" if logger && logger.info?
                else
                  logger.info "--> ContactsMailHandler: Message #{uid} NOT processed and left on the server" if logger && logger.info?
                end
              end
            end
          end
        end
        msg_count
      ensure
        if defined?(pop) && pop && pop.started?
          pop.finish
        end
      end

      private

      def logger
        ::Rails.logger
      end

    end
  end
end
