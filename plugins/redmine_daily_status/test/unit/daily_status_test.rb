require File.expand_path('../../test_helper', __FILE__)

class DailyStatusTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  	def test_should_create_project_daily_status
		assert_difference 'DailyStatus.count' do
		dailystatus = create_daily_project_status
		assert !dailystatus.new_record?, "#{dailystatus.errors.full_messages.to_sentence}"
		end
	end
	def test_should_require_daily_status_content
		assert_no_difference 'DailyStatus.count' do
		dailystatus = create_daily_project_status(:content => nil)
		assert !dailystatus, "#{dailystatus.errors.full_messages.to_sentence}"  
		end
	end
	def test_should_obtailn_daily_status_days
		assert_no_difference 'DailyStatus.count' do
		dailystatus = obtain_daily_project_status 1,1
		assert !dailystatus.nil?, "No Content available"  
		end
	end

#The below protected method creates an daily status record in the test database mentioned in database.yml

	protected
		def create_daily_project_status(options = {}) 
			record = DailyStatus.new({ :content => "Today's Status", :project_id => 1}.merge(options))
			record.save
			record
		end
		def obtain_daily_project_status(days,project_id)
			record = DailyStatus.ago days,project_id
			record
		end
end
