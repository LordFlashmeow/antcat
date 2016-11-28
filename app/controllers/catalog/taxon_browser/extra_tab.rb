# `ExtraTab`s are used for things where calling `#children` would
# not work or make sense. Everything here is a special case.
#
# Currently, there are no pages with more than one extra tab; the
# extra tab is always the last tab; and `taxon` is always the same as
# `@taxon` in `CatalogController`.

module Catalog::TaxonBrowser
  class ExtraTab < Tab
    def self.create taxon, taxon_browser
      return unless taxon_browser.display

      label = taxon.taxon_label

      title, children = case taxon_browser.display
        when :incertae_sedis_in_family, :incertae_sedis_in_subfamily
          [ "Genera <i>incertae sedis</i> in #{label}",
            taxon.genera_incertae_sedis_in ]

        when :all_genera_in_family, :all_genera_in_subfamily
          [ "All #{label} genera", taxon.all_displayable_genera ]

        when :all_taxa_in_genus
          [ "All #{label} taxa", taxon.displayable_child_taxa ]

        # Special case because:
        #   1) A genus' children are its species.
        #   2) There are no taxa with a `subgenus_id` as of 2016.
        #
        # The catalog page in this case will be that of a genus, ie the taxon
        # from which the "Subgenus" link was followed from (which is also the
        # same as `@taxon` in catalog controller).
        when :subgenera_in_genus
          [ "#{label} subgenera", taxon.displayable_subgenera ]

        # Like above, but `@taxon` (catalog controller) in this case
        # is the subgenus.
        when :subgenera_in_parent_genus
          [ "#{taxon.genus.taxon_label} subgenera",
            taxon.genus.displayable_subgenera ]

        else
          raise # It's not possible to get here by following links.
        end

      new title, children, taxon_browser
    end

    def initialize title, children, taxon_browser
      super children, taxon_browser
      @title = title.html_safe
    end

    def title
      @title
    end

    def notify_about_no_valid_children?
      false
    end

    private
      def sorted_children
        # Sorted by epithet which is used for the link labels.
        return @children.order_by_joined_epithet if display == :all_taxa_in_genus
        super
      end
  end
end
