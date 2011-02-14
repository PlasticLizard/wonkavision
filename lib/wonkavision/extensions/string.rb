class String
  def is_numeric?
    match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end
end
