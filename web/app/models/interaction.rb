class Interaction < ApplicationRecord
  belongs_to :recruiter
  belongs_to :target, class_name: "User"
  belongs_to :role, optional: true
  has_one :experience, dependent: :destroy

  validates :status, presence: true
end
