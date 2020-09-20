require 'net/http'
require 'uri'

module NotificationService
  class NotificationsController < NotificationService::ApplicationController
    include SharedModules::Serializer

    skip_before_action :verify_authenticity_token, raise: false, only: [:create]
    before_action :authenticate_service, only: [:create, :show]
    before_action :authenticate_user, only: [:index, :destroy, :run_action]
    before_action :set_notification, only: [:destroy, :run_action]
    before_action :set_notification_by_token, only: [:run_action_by_token]

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
        "? = any(recipients)", session_user.id,
      ).order('created_at DESC').to_a.reject(&:expired?)

      render json: { notifications: notifications.map { |noti| serialize(noti) } }
    end

    def show
      unifier = params[:id]
      noti = unifier.present? && Notification.where(unifier: unifier).to_a.reject(&:expired?).first
      raise SharedModules::NotFound if noti.blank?
      render json: { notification: serialize(noti) }
    end

    def create
      noti = Notification.new(
        unifier: params[:unifier],
        recipients: params[:recipients].map(&:to_i).sort,
        subject: params[:subject],
        body:    params[:body],
        fa_icon: params[:fa_icon],
        actions: params[:actions].to_a.map{|a|
          a.slice('key', 'caption', 'resource', 'method', 'params', 'button_class', 'success_message')
        },
        token: SecureRandom.base58(20),
        expiry: 2.weeks.from_now,
      )

      if noti.unifier.present? && Notification.where(unifier: noti.unifier).to_a.reject(&:expired?).size > 0
        raise SharedModules::NotAcceptable.new('Already exist')
      end

      noti.save!

      NotificationMailer.deliver_many(:notification_email, {
        notification: noti
      })

      render json: { notification: serialize(noti) }
    end

    def destroy
      @noti.destroy!
    end

    def call(action)
      resource = action['resource']
      raise SharedModules::NotFound unless resource.match?(/\Aremote_[a-z_]+\Z/)
      remote = ("SharedResources::" + resource.classify).constantize

      method = action['method'].to_sym
      allowed_methods = remote.methods - SharedResources::ApplicationResource.methods
      raise SharedModules::MethodNotAllowed if allowed_methods.exclude?(method)

      params = action['params'].to_a

      remote.generate_token session_user if session_user.present?
      remote.send(method, *params)
    end

    def run_action
      action = @noti.actions.find{|a| a['key'] == params[:action_key] }
      call(action) if action['resource']
      @noti.destroy!
    end

    def run_action_by_token
      if session_user && @noti.recipients.exclude?(session_user.id)
        redirect_to '/ict/failure/logout_first'
      elsif @noti
        action = @noti.actions.find{|a| a['key'] == params[:action_key] }
        call(action) if action['resource']
        @noti.destroy!
        if action['success_message']
          redirect_to '/ict/success/' + action['success_message']
        else
          redirect_to '/ict/success/notification'
        end
      else
        redirect_to '/ict/failure/notification'
      end
    end

    private

    def set_notification_by_token
      @noti = NotificationService::Notification.find_by(token: params[:token])
      @noti = nil if @noti&.expired?
    end

    def set_notification
      @noti = NotificationService::Notification.find_by(id: params[:id])
      raise SharedModules::NotFound if @noti.nil? || @noti.expired?
      raise SharedModules::NotAuthorized if @noti.recipients.exclude?(session_user.id)
    end
  end
end
