ActiveRecord::Schema.define do
  create_table   :movies, :force => true do |t|
    t.string     :title, :subtitles, :studio
    t.integer    :number_of_discs, :cod
    t.datetime   :dvd_release_date
    t.timestamps
  end

  create_table :people, :primary_key => :cod, :force => true do |t|
    t.string  :name
    t.integer :block_buster_id
  end

  create_table :block_busters, :force => true do |t|
    t.string :address
  end
end
