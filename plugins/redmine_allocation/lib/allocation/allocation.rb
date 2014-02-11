module Allocation
  module Allocation
    def months
      now = Time.now
      first_day =  Date.new(now.year, now.month, 1)
      months = (I18n.t :"date.month_names")
      12.times.collect do |i|
        start_date = first_day + i.months
        end_date = (start_date + 1.month).yesterday
        { :start_date => start_date,
          :end_date => end_date,
          :month_name => months[start_date.month] }
      end
    end

    def allocation_by_months(users, months)
      users.reduce({}) do |hash, user|
        hash[user] = months.reduce([]) do |inner, month|
          inner << user_allocation(user, month[:start_date], month[:end_date])
        end
        hash
      end
    end

    def user_allocation(user, from, to)
      user.memberships.reduce(0) { |sum, member| sum + member_allocation(member, from, to) }
    end

    def member_allocation(member, from, to)
      if from.nil? or to.nil? or from > to or
          (member.from_date and member.to_date and member.from_date > member.to_date)
        return 0
      end
      range_days = 1 + (to - from).to_i
      if member.from_date.nil? || member.from_date <= from
        if member.to_date.nil? || member.to_date >= to
          # member.from_date <= from, member.to_date >= to
          days = range_days
        else
          # member.from_date <= from, member.to_date < to
          days = [0, 1 + (member.to_date - from).to_i].max
        end
      elsif member.to_date.nil? || member.to_date >= to
        # member.from_date > from, member.to_date >= to
        days = [0, 1 + (to - member.from_date).to_i].max
      else
        # member.from_date > from, member.to_date < to
        days = 1 + (member.to_date - member.from_date).to_i
      end
      member.allocation.to_f * days / range_days
    end
  end
end
