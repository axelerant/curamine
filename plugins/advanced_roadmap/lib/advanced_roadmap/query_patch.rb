require_dependency "query"

module AdvancedRoadmap
  module QueryPatch
    def self.included(base)
      base.class_eval do

        # Returns the milestones
        # Valid options are :conditions
        def milestones(options = {})
          Milestone.find(:all,
                         :include => :project,
                         :conditions => Query.merge_conditions(project_statement, options[:conditions]))
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end

        # Deprecated method from Rails 2.3.X.
        def self.merge_conditions(*conditions)
          segments = []

          conditions.each do |condition|
            unless condition.blank?
              sql = sanitize_sql(condition)
              segments << sql unless sql.blank?
            end
          end

          "(#{segments.join(') AND (')})" unless segments.empty?
        end

      end
    end
  end
end
