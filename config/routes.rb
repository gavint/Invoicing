Rails.application.routes.draw do
  root "dashboard#index"

  resources :contacts

  resources :invoices do
    member do
      patch :mark_paid
      get :download_pdf
      post :send_email
      get :preview_pdf if Rails.env.development?
    end
  end

  resource :settings, only: %i[edit update]
end
