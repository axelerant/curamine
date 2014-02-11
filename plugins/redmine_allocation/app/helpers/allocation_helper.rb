module AllocationHelper
  def percent(n)
    "#{n.round(2) rescue n} %"
  end
end
