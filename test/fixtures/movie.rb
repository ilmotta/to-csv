class Movie < ActiveRecord::Base
  named_scope :number_of_discs_gte, lambda { |value| { :conditions => ['number_of_discs >= ?', value] } }
end