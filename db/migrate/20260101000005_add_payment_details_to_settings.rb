class AddPaymentDetailsToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :bank_account_name, :string
    add_column :settings, :bank_bsb, :string
    add_column :settings, :bank_account_number, :string
    add_column :settings, :pay_id, :string
  end
end
