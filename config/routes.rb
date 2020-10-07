NotificationService::Engine.routes.draw do
  resources :notifications, only: [:index, :create, :show] do
    post :run_action, on: :collection
    get :run_action_by_token, on: :collection
  end
end
