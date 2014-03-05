# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :questions do
  collection do
    get :autocomplete_for_topic
    get :topics
  end
  member do
    get :vote
  end
end

match "issues/:issue_id/move_to_forum/:board_id" => "questions#convert_issue"