class AllocationControllerTestCase < ActionController::TestCase
  # We are managing this ourselves
  self.use_transactional_fixtures = false

  def self.suite
    mysuite = super
    def mysuite.run(*args)
      ActiveRecord::Base.connection.transaction do
        create_test_data
        super
        raise ActiveRecord::Rollback
      end
    end
    mysuite
  end

  def admin_login
    @request.session[:user_id] = User.find_by_login("admin").id
  end
end
