class SettingsController < ApplicationController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:company_name, :company_email, :company_phone,
      :company_address_line1, :company_address_line2, :company_city, :company_state,
      :company_zip, :company_country, :invoice_footer_note,
      :smtp_address, :smtp_port, :smtp_username, :smtp_password)
  end
end
