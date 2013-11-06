class AutomaticMembershipsController < ApplicationController
  unloadable
  layout 'admin'
  before_filter :require_admin

  def index
    @roles = Role.sorted.givable.all
    @users = User.logged.status(User::STATUS_ACTIVE)
    @groups = Group.sorted.all
    if request.post?
      @users.each do |user|
        user.create_automatic_membership if user.automatic_membership.nil?
        user.automatic_membership.role_ids = params[:automatic_memberships][user.id.to_s]
        user.save
      end
      @groups.each do |group|
        group.create_automatic_membership if group.automatic_membership.nil?
        group.automatic_membership.role_ids = params[:automatic_memberships][group.id.to_s]
        group.save
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    end
  end
end
