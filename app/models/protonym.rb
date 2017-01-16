# TODO fix this issue in the database.
# All protonyms have authorships: # `Protonym.where(authorship: nil).count` # 0
# New protonyms cannot be created without a reference,
# but there are 16 of them in the db.
#
# Protonym.count                                         # 24512
# joined = Protonym.joins(authorship: :reference)
# joined.where("references.year IS NOT NULL").count      # 24496
# joined.where("references.year IS NULL").count          # 16

class Protonym < ActiveRecord::Base
  attr_accessible :fossil, :sic, :locality, :id, :name_id, :name, :authorship, :taxon

  belongs_to :authorship, class_name: 'Citation', dependent: :destroy
  belongs_to :name

  has_one :taxon

  validates :authorship, presence: true
  validates :name, presence: true

  accepts_nested_attributes_for :name, :authorship
  has_paper_trail meta: { change_id: proc { UndoTracker.get_current_change_id } }
end
