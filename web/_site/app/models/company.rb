class Company < ApplicationRecord
  has_many :recruiters, dependent: :nullify
  has_many :reviews, dependent: :nullify

  validates :name, presence: true
end

