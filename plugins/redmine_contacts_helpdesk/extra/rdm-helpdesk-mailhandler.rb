#!/usr/bin/env ruby

# == Synopsis
#
# Reads an email from standard input and forward it to a Redmine server
# through a HTTP request.
#
# == Usage
#
#    rdm-helpdesk-mailhandler [options] --url=<Redmine URL> --key=<API key>
#
# == Arguments
# 
#   -u, --url                      URL of the Redmine server
#   -k, --key                      Redmine API key
#   
# General options:
#       --unknown-user=ACTION      how to handle emails from an unknown user
#                                  ACTION can be one of the following values:
#                                  ignore: email is ignored (default)
#                                  accept: accept as anonymous user
#                                  create: create a user account
#       --no-permission-check      disable permission checking when receiving
#                                  the email
#       --key-file=PATH            path to a file that contains the Redmine
#                                  API key (use this option instead of --key
#                                  if you don't the key to appear in the
#                                  command line)
#       --no-check-certificate     do not check server certificate
#   -h, --help                     show this help
#   -v, --verbose                  show extra information
#   -V, --version                  show version information and exit
# 
# Issue attributes control options:
#   -p, --project=PROJECT          identifier of the target project
#   -s, --status=STATUS            name of the target status
#   -t, --tracker=TRACKER          name of the target tracker
#       --category=CATEGORY        name of the target category
#       --priority=PRIORITY        name of the target priority
#       
# == Examples
#
# Fixed project and default tracker specified, but emails can override
# both tracker and priority attributes using keywords:
# 
#   rdm-mailhandler --url https://domain.foo/redmine --key secret \\
#                   --project foo \\
#                   --tracker bug \\
#                   --allow-override tracker,priority

require 'net/http'
require 'net/https'
require 'uri'
require 'getoptlong'
require 'rdoc/usage'

module Net
  class HTTPS < HTTP
    def self.post_form(url, params, headers, options={})
      request = Post.new(url.path)
      request.form_data = params
      request.basic_auth url.user, url.password if url.user
      request.initialize_http_header(headers)
      http = new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      if options[:no_check_certificate]
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.start {|h| h.request(request) }
    end
  end
end

class HelpdeskMailHandler
  VERSION = '0.1'
  
  attr_accessor :verbose, :issue_attributes, :unknown_user, :no_permission_check, :url, :key, :no_check_certificate

  def initialize
    self.issue_attributes = {}
    
    opts = GetoptLong.new(
      [ '--help',           '-h', GetoptLong::NO_ARGUMENT ],
      [ '--version',        '-V', GetoptLong::NO_ARGUMENT ],
      [ '--verbose',        '-v', GetoptLong::NO_ARGUMENT ],
      [ '--url',            '-u', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--key',            '-k', GetoptLong::REQUIRED_ARGUMENT],
      [ '--key-file',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--project',        '-p', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--status',         '-s', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--tracker',        '-t', GetoptLong::REQUIRED_ARGUMENT],
      [ '--category',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--priority',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--unknown-user',         GetoptLong::REQUIRED_ARGUMENT],
      [ '--no-permission-check',  GetoptLong::NO_ARGUMENT],
      [ '--no-check-certificate', GetoptLong::NO_ARGUMENT]
    )

    opts.each do |opt, arg|
      case opt
      when '--url'
        self.url = arg.dup
      when '--key'
        self.key = arg.dup
      when '--key-file'
        begin
          self.key = File.read(arg).strip
        rescue Exception => e
          $stderr.puts "Unable to read the key from #{arg}: #{e.message}"
          exit 1
        end
      when '--help'
        usage
      when '--verbose'
        self.verbose = true
      when '--version'
        puts VERSION; exit
      when '--project', '--status', '--tracker', '--category', '--priority'
        self.issue_attributes[opt.gsub(%r{^\-\-}, '')] = arg.dup
      when '--unknown-user'
        self.unknown_user = arg.dup
      when '--no-permission-check'
        self.no_permission_check = '1'
      when '--no-check-certificate'
        self.no_check_certificate = true
      end
    end
    
    RDoc.usage if url.nil?
  end
  
  def submit(email)
    uri = url.gsub(%r{/*$}, '') + '/helpdesk_mailer'
    
    headers = { 'User-Agent' => "Redmine helpdesk mail handler/#{VERSION}" }
    
    data = { 'key' => key, 'email' => email, 
                           'unknown_user' => unknown_user,
                           'no_permission_check' => no_permission_check}
    issue_attributes.each { |attr, value| data["issue[#{attr}]"] = value }
             
    debug "Posting to #{uri}..."
    response = Net::HTTPS.post_form(URI.parse(uri), data, headers, :no_check_certificate => no_check_certificate)
    debug "Response received: #{response.code}"
    
    case response.code.to_i
      when 403
        warn "Request was denied by your Redmine server. " + 
             "Make sure that 'WS for incoming emails' is enabled in application settings and that you provided the correct API key."
        return 77
      when 422
        warn "Request was denied by your Redmine server. " +
             "Possible reasons: email is sent from an invalid email address or is missing some information."
        return 77
      when 400..499
        warn "Request was denied by your Redmine server (#{response.code})."
        return 77
      when 500..599
        warn "Failed to contact your Redmine server (#{response.code})."
        return 75
      when 201
        debug "Proccessed successfully"
        return 0
      else
        return 1
    end
  end
  
  private
  
  def debug(msg)
    puts msg if verbose
  end
end

handler = HelpdeskMailHandler.new
exit(handler.submit(STDIN.read))
