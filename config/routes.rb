NotificationService::Engine.routes.draw do
  resources :notifications, only: [:index, :create, :destroy] do
    post :run_action, on: :member
    post :postpone, on: :member
  end
end
