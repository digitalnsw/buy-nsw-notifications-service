require 'net/http'
require 'uri'

module NotificationService
  class NotificationsController < NotificationService::ApplicationController
    include SharedModules::Serializer

    skip_before_action :verify_authenticity_token, raise: false, only: [:create]
    before_action :authenticate_service, only: [:create]
    before_action :authenticate_user, only: [:index, :destroy, :postpone, :run_action]
    before_action :set_notification, only: [:destroy, :postpone, :run_action]

    def serialize(noti)
      escape_recursive(
        {
          id: noti.id,
          subject: noti.subject,
          body: noti.body,
          fa_icon: noti.fa_icon,
          created_at: noti.created_at,
          actions: noti.actions&.map do |action|
            {
              key: action['key'],
              caption: action['caption'],
            }
          end
        }
      )
    end

    def index
      notifications = NotificationService::Notification.where(
        user_id: session_user.id,
      ).order('created_at DESC').to_a.select do |noti|
        noti.postponed_for.nil? || noti.postponed_for < Time.now
      end
      render json: notifications.map do |noti|
        serialize(noti)
      end
    end

    def create
      noti = NotificationService::Notification.create!(
        user_id: params["user_id"],
        subject: params["subject"],
        body:    params["body"],
        fa_icon: params["fa_icon"],
        actions: params["actions"],
      )
      render json: serialize(noti)
    end

    def destroy
      @noti.destroy!
    end

    def postpone
      @noti.update_attributes!(postponed_for: 7.days.from_now)
    end

    def call(action)
      uri = URI.parse("http://localhost:3000" + action['callback']['url'])
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = action['callback']['params']
      response = http.request(request)
    end

    def run_action
      action = @noti.actions.find{|a| a['key'] == params[:action_key] }
      callback(action)
      @noti.destroy!
    end

    private

    def set_notification
      @noti = NotificationService::Notification.find_by!(user_id: session_user.id, id: params[:id])
    end
  end
end
