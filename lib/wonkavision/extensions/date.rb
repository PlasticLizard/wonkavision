class Date
  def to_utc_time
    to_time.utc.beginning_of_day
  end
end