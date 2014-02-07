#custom routes for this plugin
resources :helpdesk_tickets, :only => [:edit, :destroy, :update]

resources :projects do
  resources :canned_responses, :only => [:new, :create]
end

resources :canned_responses do
  collection do
    post :add 
  end
end

match "helpdesk_mailer" => "helpdesk_mailer#index"
match "helpdesk_mailer/get_mail" => "helpdesk_mailer#get_mail"
match "helpdesk/save_settings" => "helpdesk#save_settings"
match "helpdesk/get_mail" => "helpdesk#get_mail"
match "helpdesk/delete_spam/:id" => "helpdesk#delete_spam"
match "helpdesk/email_note.:format" => "helpdesk#email_note"
match "helpdesk/create_ticket.:format" => "helpdesk#create_ticket"
match "helpdesk/show_original" => "helpdesk#show_original"
match "helpdesk/:action" => 'helpdesk'
match "helpdesk_reports/:action/(:project_id)" => 'helpdesk_reports'

get "mail_fetcher/receive_imap" => "mail_fetcher#receive_imap"
get "mail_fetcher/receive_pop3" => "mail_fetcher#receive_pop3"

match 'tickets/:id/:hash' => 'public_tickets#show', :as => :public_ticket
match 'tickets/:id/add_comment/:hash' => 'public_tickets#add_comment', :as => :public_ticket_add_comment

get 'attachments/:id/:ticket_id/:hash/:filename', :to => 'attachments#show', :id => /\d+/, :filename => /.*/, :as => 'hashed_named_attachment'
get 'attachments/download_hashed/:id/:ticket_id/:hash/:filename', :to => 'attachments#download', :id => /\d+/, :filename => /.*/, :as => 'hashed_download_named_attachment'
