class ModerationAction < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true

  validates :action, presence: true
end

