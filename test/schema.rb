ActiveRecord::Schema.define :version => 1 do
  create_table :sample_codes, :force => true do |t|
    t.integer :code1, :null => false, :default => 0, :unsigned => true
    t.integer :code2, :default => 99
    t.integer :code3, :null => false, :unsigned => true
  end
end
