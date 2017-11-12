class Subgenus < GenusGroupTaxon
  attr_accessible :subfamily, :tribe, :genus, :homonym_replaced_by

  belongs_to :genus

  # No taxa have a `subgenus_id` as of 2016.
  has_many :species

  validates :genus, presence: true

  # TODO move to `Taxa::CallbacksAndValidations` once we're ready for it.
  validate :ensure_correct_name_type

  def parent
    genus
  end

  def statistics valid_only: false; end

  private
    def ensure_correct_name_type
      return if name.is_a? name_class
      error_message = "`Taxon` (#{self.class}) and `Name` (#{name.class}) types must match"
      errors.add :base, error_message unless errors.added? :base, error_message
      false
    end
end
