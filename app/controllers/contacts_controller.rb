class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show edit update destroy]

  def index
    @contacts = Contact.order(:name)
  end

  def show
    @invoices = @contact.invoices.order(issue_date: :desc)
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      redirect_to @contact, notice: "Contact created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @contact.update(contact_params)
      redirect_to @contact, notice: "Contact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @contact.destroy
      redirect_to contacts_path, notice: "Contact deleted."
    else
      redirect_to contacts_path, alert: @contact.errors.full_messages.to_sentence
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :company_name, :email, :phone,
      :billing_address_line1, :billing_address_line2, :billing_city,
      :billing_state, :billing_zip, :billing_country, :notes)
  end
end
