module Operations
  class CreateNewCombination
    include Operation

    def self.description current_valid_taxon:, new_combination_name:, new_genus:
      preview_new_taxon = PreviewString.new(new_combination_name + ' **[NEW TAXON]**')
      preview_existing_taxon = PreviewTaxon.new(current_valid_taxon)
      preview_new_genus = PreviewTaxon.new(new_genus)

      [
        "##### Operation: `CreateNewCombinationRecord`",
        CreateNewCombinationRecord.description(
          current_valid_taxon: preview_existing_taxon,
          new_genus: preview_new_genus,
          target_name_string: preview_new_taxon
        ),

        "##### Operation: `MoveHistoryItems`",
        MoveHistoryItems.description(to_taxon: preview_new_taxon, history_items: current_valid_taxon.history_items),

        "##### Operation: `ConvertToObsoleteCombination`",
        ConvertToObsoleteCombination.description(
          current_valid_taxon: preview_existing_taxon,
          new_combination: preview_new_taxon
        )
      ].join("\n")
    end

    def initialize current_valid_taxon:, new_genus:, target_name_string:
      @current_valid_taxon = current_valid_taxon
      @new_genus = new_genus
      @target_name_string = target_name_string
    end

    def execute
      new_combination = Operations::CreateNewCombinationRecord.new(
        current_valid_taxon: current_valid_taxon,
        new_genus: new_genus,
        target_name_string: target_name_string
      ).run(context).results.new_combination
      results.new_combination = new_combination

      Operations::MoveHistoryItems.new(
        to_taxon: new_combination,
        history_items: current_valid_taxon.history_items
      ).run(context)

      Operations::ConvertToObsoleteCombination.new(
        current_valid_taxon: current_valid_taxon,
        new_combination: new_combination
      ).run(context)
    end

    class PreviewTaxon < SimpleDelegator
      def to_s
        __getobj__.link_to_taxon
      end
    end

    class PreviewString
      def initialize string
        @string = string
      end

      def to_s
        @string
      end

      def method_missing name, *_args, &_block
        "missing - #{name}" || super
      end

      def respond_to_missing? _name, *_args
        super
      end
    end

    private

      attr_reader :current_valid_taxon, :new_genus, :target_name_string
  end
end