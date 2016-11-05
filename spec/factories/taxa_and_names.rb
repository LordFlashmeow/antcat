# TODO this creates too many objects and it seems to create new associations
# even when it's passed existing objects.
#
# Creating a taxon of a lower rank creates all the taxa above it as specified
# by the factories. This also create objects for their dependencies, such
# as the protonym, which in turn creates a new citation --> another reference
# --> another author --> etc etc = many objects.

FactoryGirl.define do
  factory :name do
    sequence(:name) { |n| raise }
    name_html { name }
    epithet { name }
    epithet_html { name_html }
  end

  factory :family_name do
    name 'Formicidae'
    name_html { name }
    epithet { name }
    epithet_html { name_html }
  end

  factory :subfamily_name do
    sequence(:name) { |n| "Subfamily#{n}" }
    name_html { name }
    epithet { name }
    epithet_html { name_html }
  end

  factory :tribe_name do
    sequence(:name) { |n| "Tribe#{n}" }
    name_html { name }
    epithet { name }
    epithet_html { name_html }
  end

  factory :subtribe_name do
    sequence(:name) { |n| "Subtribe#{n}" }
    name_html { name }
    epithet { name }
    epithet_html { name_html }
  end

  factory :genus_name do
    sequence(:name) { |n| "Genus#{n}" }
    name_html { "<i>#{name}</i>" }
    epithet { name }
    epithet_html { "<i>#{name}</i>" }
  end

  # TODO possibly broken
  # from prod db
  # Subgenus.first.name.name_html # "<i>Lasius</i> <i>(Acanthomyops)</i>"
  #
  # from
  # $rails console test --sandbox
  # SunspotTest.stub
  # FactoryGirl.create :subgenus
  # Subgenus.first.name.name_html # "<i>Atta</i> <i>(Atta (Subgenus2))</i>"
  factory :subgenus_name do
    sequence(:name) { |n| "Atta (Subgenus#{n})" }
    name_html { "<i>Atta</i> <i>(#{name})</i>" }
    epithet { name.split(' ').last }
    epithet_html { "<i>#{epithet}</i>" }
  end

  factory :species_name do
    sequence(:name) { |n| "Atta species#{n}" }
    name_html { "<i>#{name}</i>" }
    epithet { name.split(' ').last }
    epithet_html { "<i>#{epithet}</i>" }
  end

  factory :subspecies_name do
    sequence(:name) { |n| "Atta species subspecies#{n}" }
    name_html { "<i>#{name}</i>" }
    epithet { name.split(' ').last }
    epithets { name.split(' ')[-2..-1].join(' ') }
    epithet_html { "<i>#{epithet}</i>" }
  end

  factory :taxon do
    association :name, factory: :genus_name
    association :type_name, factory: :species_name
    protonym
    status 'valid'
    taxon_state
  end

  factory :family do
    association :name, factory: :family_name
    association :type_name, factory: :genus_name
    protonym
    status 'valid'
    taxon_state
  end

  factory :subfamily do
    association :name, factory: :subfamily_name
    association :type_name, factory: :genus_name
    protonym
    status 'valid'
    taxon_state
  end

  factory :tribe do
    association :name, factory: :tribe_name
    association :type_name, factory: :genus_name
    subfamily
    protonym
    status 'valid'
    taxon_state
  end

  # FIX? Broken. The are 8 SubtribeName:s in the prod db, but no
  # Subtribe:s, so low-priority.
  factory :subtribe do
    association :name, factory: :subtribe_name
    association :type_name, factory: :genus_name
    subfamily
    protonym
    status 'valid'
    taxon_state
  end

  factory :genus do
    association :name, factory: :genus_name
    association :type_name, factory: :species_name
    tribe
    subfamily { |a| a.tribe && a.tribe.subfamily }
    protonym
    status 'valid'
    taxon_state
  end

  factory :subgenus do
    association :name, factory: :subgenus_name
    association :type_name, factory: :species_name
    genus
    protonym
    status 'valid'
    taxon_state
  end

  factory :species_group_taxon do
    association :name, factory: :species_name
    genus
    protonym
    status 'valid'
    taxon_state
  end

  factory :species do
    association :name, factory: :species_name
    genus
    protonym
    status 'valid'
    taxon_state
  end

  factory :subspecies do
    association :name, factory: :species_name
    species
    genus
    protonym
    status 'valid'
    taxon_state
  end
end

# TODO probably remove and use this name for `#create_taxon_object`.
def create_taxon name_or_attributes = 'Atta', attributes = {}
  create_taxon_object name_or_attributes, :genus, attributes
end

def create_family
  create_taxon_object 'Formicidae', :family
end

def create_subfamily name_or_attributes = 'Dolichoderinae', attributes = {}
  create_taxon_object name_or_attributes, :subfamily, attributes
end

def create_tribe name_or_attributes = 'Attini', attributes = {}
  create_taxon_object name_or_attributes, :tribe, attributes
end

def create_genus name_or_attributes = 'Atta', attributes = {}
  create_taxon_object name_or_attributes, :genus, attributes
end

def create_subgenus name_or_attributes = 'Atta (Subatta)', attributes = {}
  create_taxon_object name_or_attributes, :subgenus, attributes
end

def create_species name_or_attributes = 'Atta major', attributes = {}
  create_taxon_object name_or_attributes, :species, attributes
end

def create_subspecies name_or_attributes = 'Atta major minor', attributes = {}
  create_taxon_object name_or_attributes, :subspecies, attributes
end

def create_taxon_object name_or_attributes, rank, attributes = {}
  taxon_factory = rank
  name_factory = "#{rank}_name".to_sym

  attributes =
    if name_or_attributes.kind_of? String
      name, epithet, epithets = get_name_parts name_or_attributes
      name_object = create name_factory, name: name, epithet: epithet, epithets: epithets
      attributes.reverse_merge name: name_object, name_cache: name
    else
      name_or_attributes
    end

  build_stubbed = attributes.delete :build_stubbed
  build = attributes.delete :build
  build_stubbed ||= build
  FactoryGirl.send(build_stubbed ? :build_stubbed : :create, taxon_factory, attributes)
end

def get_name_parts name
  parts = name.split ' '
  epithet = parts.last
  epithets = parts[1..-1].join(' ') unless parts.size < 2
  return name, epithet, epithets
end

def find_or_create_name name
  name, epithet, epithets = get_name_parts name
  create :name, name: name, epithet: epithet, epithets: epithets
end

def create_species_name name
  name, epithet, epithets = get_name_parts name
  create :species_name, name: name, epithet: epithet, epithets: epithets
end

def create_subspecies_name name
  name, epithet, epithets = get_name_parts name
  create :subspecies_name, name: name, epithet: epithet, epithets: epithets
end

def create_synonym senior, attributes = {}
  junior = create_genus attributes.merge status: 'synonym'
  synonym = Synonym.create! senior_synonym: senior, junior_synonym: junior
  junior
end

def create_taxon_version_and_change review_state, user = @user, approver = nil, genus_name = 'default_genus'
  name = create :name, name: genus_name
  taxon = create :genus, name: name
  taxon.taxon_state.review_state = review_state

  change = create :change, user_changed_taxon_id: taxon.id, change_type: "create"
  create :version, item_id: taxon.id, whodunnit: user.id, change_id: change.id

  if approver
    change.update_attributes! approver: approver, approved_at: Time.now
  end

  taxon
end
