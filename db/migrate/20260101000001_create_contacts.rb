class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :company_name
      t.string :email, null: false
      t.string :phone
      t.string :billing_address_line1
      t.string :billing_address_line2
      t.string :billing_city
      t.string :billing_state
      t.string :billing_zip
      t.string :billing_country
      t.text :notes

      t.timestamps
    end
  end
end
