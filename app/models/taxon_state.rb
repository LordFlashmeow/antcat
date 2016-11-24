# TODO default `taxon_states.deleted` to "false" in db.

class TaxonState < ActiveRecord::Base
  belongs_to :taxon

  # TODO investigate the difference between `TaxonState.waiting` and
  # `Change.waiting`. I believe the difference has to do with `Change`
  # counting all changes, so editing the same taxon twice --> 2 waiting changes,
  # but the taxon only has a single taxon state, so --> 1 waiting taxon state.
  scope :waiting, -> { where(review_state: 'waiting') }

  has_paper_trail
end
