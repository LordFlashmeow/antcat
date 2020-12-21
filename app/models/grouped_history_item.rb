# frozen_string_literal: true

class GroupedHistoryItem
  attr_reader :items

  # TODO: This should be delegated to the definiton once they have been extracted into new classes.
  delegate :groupable?, :group_key, :type, to: :any_item_in_group

  def initialize items
    @items = items
  end

  def taxt
    @_taxt ||= any_item_in_group.section_to_taxt(item_taxts)
  end

  def grouped?
    !items.one?
  end

  private

    # HACK: `items.first` is because any item in the same group can be used...
    def any_item_in_group
      @_any_item_in_group ||= items.first
    end

    def item_taxts
      items.map(&:groupable_item_taxt).join('; ')
    end
end
