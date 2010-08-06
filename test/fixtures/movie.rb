class Movie < ActiveRecord::Base
  belongs_to :person, :foreign_key => :cod
  named_scope :number_of_discs_gte, lambda { |value| { :conditions => ['number_of_discs >= ?', value] } }

  def self.dvd_release_date_lte(date)
    scoped :conditions => ["dvd_release_date <= ?", date]
  end
end
