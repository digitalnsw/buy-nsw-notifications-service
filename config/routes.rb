NotificationService::Engine.routes.draw do
  resources :notifications, only: [:index, :create, :show, :destroy] do
    post :run_action, on: :collection
    get :run_action_by_token, on: :collection
  end
end
