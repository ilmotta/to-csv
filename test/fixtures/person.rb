class Person < ActiveRecord::Base
  has_many :movies, :foreign_key => :cod
  belongs_to :block_buster
  set_primary_key :cod
end
