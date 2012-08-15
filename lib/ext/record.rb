class Record
  field :measure_ids, type: Array
  belongs_to :measure
  
  scope :belongs_to_measure, ->(measure_id) { where('measures' => measure_id) }
end
