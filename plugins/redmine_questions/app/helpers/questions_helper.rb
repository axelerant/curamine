module QuestionsHelper
  def vote_tag(object, user, options={})
    content_tag("span", vote_link(object, user))
  end

  def vote_link(object, user)
    return '' unless user && user.logged? && user.respond_to?('voted_for?')
    voted = user.voted_for?(object)
    url = {:controller => 'questions', :action => 'vote', :id => object}
    link_to((voted ? l(:button_questions_unvote) : l(:button_questions_vote)), url, 
      :class => (voted ? 'icon icon-vote' : 'icon icon-unvote'))

  end  

end
