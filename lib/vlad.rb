# coding: UTF-8
class Vlad

  def self.idate show_progress = false
    Progress.new_init show_progress: show_progress

    @results = {}
    @results.merge! record_counts
    @results.merge! genera_with_tribes_but_not_subfamilies
    @results.merge! taxa_with_mismatched_synonym_and_status
    @results.merge! taxa_with_mismatched_homonym_and_status
    @results.merge! duplicates

    display
    @results
  end

  def self.display_results_section section, options = {}
    options = options.reverse_merge sort: true
    results_section = @results[section]
    return unless results_section.present?

    Progress.puts section.to_s.gsub(/_/, ' ').capitalize

    lines = results_section.map do |item|
      yield item
    end

    lines.sort! if options[:sort]

    for line in lines
      Progress.puts '  ' + line
    end

    Progress.puts
  end

  def self.display
    Progress.puts

    display_results_section :record_counts, :sort => false do |count|
      "#{count[:count].to_s.rjust(7)} #{count[:table]}"
    end

    display_results_section :genera_with_tribes_but_not_subfamilies do |genus|
      "#{genus.name} (tribe #{genus.tribe.name})"
    end

    #display_results_section :taxa_with_mismatched_synonym_and_status do |taxon|
      #"#{taxon.name} #{taxon.status} #{taxon.synonym_of_id}"
    #end

    #display_results_section :taxa_with_mismatched_homonym_and_status do |taxon|
      #"#{taxon.name} #{taxon.status} #{taxon.homonym_replaced_by_id}"
    #end

    #display_results_section :duplicates do |duplicate|
      #"#{duplicate[:name]} #{duplicate[:count]}"
    #end

  end

  def self.duplicates
    {duplicates: Taxon.select('name, COUNT(name) AS count').group(:name, :genus_id).having('COUNT(name) > 1')}
  end

  def self.taxa_with_mismatched_synonym_and_status
    {taxa_with_mismatched_synonym_and_status: Taxon.where("(status = 'synonym') = (synonym_of_id IS NULL)")}
  end

  def self.taxa_with_mismatched_homonym_and_status
    {taxa_with_mismatched_homonym_and_status: Taxon.where("(status = 'homonym') = (homonym_replaced_by_id IS NULL)")}
  end

  def self.genera_with_tribes_but_not_subfamilies
    {genera_with_tribes_but_not_subfamilies: Genus.where("tribe_id IS NOT NULL AND subfamily_id IS NULL")}
  end

  def self.record_counts
    {:record_counts => [
      AuthorName,
      Author,
      Bolton::Match,
      Bolton::Reference,
      Citation,
      ForwardReference,
      Journal,
      Place,
      Protonym,
      Publisher,
      ReferenceAuthorName,
      ReferenceDocument,
      Reference,
      Taxon,
      TaxonomicHistoryItem,
      User,
    ].map do |table|
      {table: table.to_s, count: table.count}
    end}
  end

end
