#ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
Time::DATE_FORMATS.merge!(
  :default => '%d/%m/%Y',
  :date_time12  => "%d/%m/%Y %I:%M%p",
  :date_time24  => "%d/%m/%Y %H:%M"
)

