NotificationService::Engine.routes.draw do
  resources :notifications, only: [:index, :create, :destroy, :show] do
    post :run_action, on: :member
    get :run_action_by_token, on: :collection
  end
end
