# 'Extra omkostnad (knuten till placering)'
class PlacementExtraCost < ApplicationRecord
  belongs_to :placement, touch: true

  validates_presence_of :date, :amount
  validates :amount, numericality: true, allow_blank: true
end
