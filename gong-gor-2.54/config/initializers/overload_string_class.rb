String.class_eval do
  def upcase
    strip.mb_chars.upcase.to_s
  end
end
