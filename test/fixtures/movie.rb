class Movie < ActiveRecord::Base
  named_scope :number_of_discs_gte, lambda { |value| { :conditions => ['number_of_discs >= ?', value] } }
  
  def self.dvd_release_date_lte(date)
    scoped :conditions => ["dvd_release_date <= ?", date]
  end
end