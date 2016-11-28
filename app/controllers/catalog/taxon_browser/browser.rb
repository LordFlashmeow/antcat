# TODO rename `@display`?

# This class is responsibe for preparing all tabs for `_taxon_browser.haml`.

module Catalog::TaxonBrowser
  class Browser
    attr_reader :tabs, :display

    def initialize taxon, show_invalid, display
      @taxon = taxon
      @show_invalid = show_invalid
      @display = default_or_display display

      setup_tabs
    end

    def show_invalid?
      @show_invalid
    end

    def selected_in_tab? taxon
      taxon.in? taxon_and_ancestors
    end

    def tab_open? tab
      @tabs.last == tab
    end

    private
      def default_or_display display
        case @taxon
        when Subfamily then :all_genera_in_subfamily if display.blank?
        when Subgenus  then :subgenera_in_parent_genus
        end || display
      end

      def setup_tabs
        @tabs = taxa_for_tabs.map do |taxon|
          TaxonTab.new taxon, self
        end

        extra_tab = ExtraTab.create @taxon, self
        @tabs << extra_tab if extra_tab
      end

      # Follows the "main progression", which from the lowest rank and up is:
      # Subspecies -> Species -> Genus -> Tribe -> Subfamily -> Family.
      # See https://github.com/calacademy-research/antcat/wiki/For-developers
      def taxa_for_tabs
        # We do not want to include all ranks in the tabs.
        taxon_and_ancestors.reject do |taxon|
          # Never show the [children of] subspecies tab (has no children).
          taxon.is_a?(Subspecies) ||

          # Don't show [subspecies in] species tab unless the species has subspecies.
          (taxon.is_a?(Species) && !taxon.children.exists?) ||

          # Hide [species in] subgenus tab because there are none as of 2016.
          taxon.is_a?(Subgenus)
        end
      end

      def taxon_and_ancestors
        return @_taxon_and_ancestors if defined? @_taxon_and_ancestors

        @_taxon_and_ancestors = []
        current_taxon = @taxon

        while current_taxon
          @_taxon_and_ancestors << current_taxon
          current_taxon = current_taxon.parent
        end

        # Reversed to put Formicidae in the first tab and itself in last.
        @_taxon_and_ancestors.reverse
      end
  end
end
