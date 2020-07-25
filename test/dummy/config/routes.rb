Rails.application.routes.draw do
  mount NotificationService::Engine => "/notification_service"
end
