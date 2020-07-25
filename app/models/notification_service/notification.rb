module NotificationService
  class Notification < ApplicationRecord
    self.table_name = 'notifications'
    acts_as_paranoid column: :discarded_at
  end
end
