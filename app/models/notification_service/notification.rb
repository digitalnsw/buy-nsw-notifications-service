module NotificationService
  class Notification < ApplicationRecord
    self.table_name = 'notifications'
    acts_as_paranoid column: :discarded_at

    def expired?
      expiry.present? && expiry < Time.now
    end
  end
end
