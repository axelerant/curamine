require File.dirname(__FILE__) + '/../test_helper'

class AllocationClass
  include Allocation::Allocation
end

class AllocationModuleTest < ActiveSupport::TestCase
  test "allocation is zero when dates are not valid" do
    allocation = AllocationClass.new
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100),
                                                 nil, nil)
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100),
                                                 Date.new(2012, 1, 1), nil)
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100),
                                                 nil, Date.new(2012, 6, 1))
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100),
                                                 Date.new(2012, 6, 1), Date.new(2012, 1, 1))
  end

  test "allocation is 100% when interval dates are in between member dates" do
    allocation = AllocationClass.new
    assert_equal 100, allocation.member_allocation(Member.new(:allocation => 100),
                                                   Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 100, allocation.member_allocation(Member.new(:allocation => 100,
                                                              :from_date => Date.new(2012, 1, 1)),
                                                   Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 100, allocation.member_allocation(Member.new(:allocation => 100,
                                                              :to_date => Date.new(2012, 6, 1)),
                                                   Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 100, allocation.member_allocation(Member.new(:allocation => 100,
                                                              :from_date => Date.new(2012, 1, 1),
                                                              :to_date => Date.new(2012, 6, 1)),
                                                   Date.new(2012, 3,1), Date.new(2012, 3, 31))
  end

  test "allocation is partial when interval and member dates overlap partially" do
    allocation = AllocationClass.new
    assert_equal 1000.0/31, allocation.member_allocation(Member.new(:allocation => 100,
                                                                    :to_date => Date.new(2012, 3, 10)),
                                                         Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 1000.0/31, allocation.member_allocation(Member.new(:allocation => 100,
                                                                    :from_date => Date.new(2012, 3, 22)),
                                                         Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 1000.0/31, allocation.member_allocation(Member.new(:allocation => 100,
                                                                    :from_date => Date.new(2012, 3, 10),
                                                                    :to_date => Date.new(2012, 3, 19)),
                                                         Date.new(2012, 3, 1), Date.new(2012, 3, 31))
  end

  test "allocation is zero when interval and member dates do not overlap" do
    allocation = AllocationClass.new
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100,
                                                            :from_date => Date.new(2012, 3, 1),
                                                            :to_date => Date.new(2012, 3, 15)),
                                                 Date.new(2012, 4, 1), Date.new(2012, 4, 30))
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100,
                                                            :to_date => Date.new(2012, 3, 15)),
                                                 Date.new(2012, 4, 1), Date.new(2012, 4, 30))
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100,
                                                            :from_date => Date.new(2012, 4, 15),
                                                            :to_date => Date.new(2012, 4, 30)),
                                                 Date.new(2012, 3, 1), Date.new(2012, 3, 31))
    assert_equal 0, allocation.member_allocation(Member.new(:allocation => 100,
                                                            :from_date => Date.new(2012, 4, 15)),
                                                 Date.new(2012, 3, 1), Date.new(2012, 3, 31))
  end
end
