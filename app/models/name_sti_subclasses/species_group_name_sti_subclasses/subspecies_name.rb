# frozen_string_literal: true

class SubspeciesName < SpeciesGroupName
  def subspecies_epithet
    cleaned_name_parts[2]
  end

  def short_name
    [genus_epithet[0] + '.', species_epithet[0] + '.', subspecies_epithet].join(' ')
  end
end
