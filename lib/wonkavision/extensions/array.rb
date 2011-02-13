class Array
  def add_options!(new_options)
    opts = length > 1 ? extract_options! : {}
    opts.merge!(new_options)
    push opts
    self
  end
end
