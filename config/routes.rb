Prelaunchr::Application.routes.draw do

  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  root :to => "users#new"

  post 'users/create' => 'users#create'
  get 'refer-a-friend' => 'users#refer'

  post 'refer-a-friend' => 'users#refer'
  get 'faq' => 'users#faq'
  get 'swag' => 'users#swag'

  get 'logout' => 'users#logout'

  resources :users, :only => [:show, :update, :edit]
  resources :subscribers

  unless Rails.application.config.consider_all_requests_local
    get '*not_found', to: 'users#redirect', :format => false
  end
end
