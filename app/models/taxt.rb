# frozen_string_literal: true

module Taxt
  # A "taxtable" is a plaintext database column which may contain "taxt" tags,
  # which render with special markup and/or resolves to a `Taxon`, `Reference`, or `Protonym` record.
  TAXTABLES = [
    [ReferenceSection, 'reference_sections',  'references_taxt'],
    [ReferenceSection, 'reference_sections',  'subtitle_taxt'],
    [ReferenceSection, 'reference_sections',  'title_taxt'],
    [Protonym,         'protonyms',           'etymology_taxt'],
    [Protonym,         'protonyms',           'primary_type_information_taxt'],
    [Protonym,         'protonyms',           'secondary_type_information_taxt'],
    [Protonym,         'protonyms',           'type_notes_taxt'],
    [Protonym,         'protonyms',           'notes_taxt'],
    [HistoryItem,      'history_items',       'taxt']
  ]

  TAX_TAG_REGEX = /\{tax (?<taxon_id>\d+)\}/
  TAXAC_TAG_REGEX = /\{taxac (?<taxon_id>\d+)\}/
  TAX_OR_TAXAC_TAG_REGEX = /\{(?:tax|taxac) (?<taxon_id>[0-9]+\})/

  PRO_TAG_REGEX = /\{pro (?<protonym_id>\d+)\}/
  PROAC_TAG_REGEX = /\{proac (?<protonym_id>\d+)\}/
  PROTT_TAG_REGEX = /\{prott (?<protonym_id>\d+)\}/

  REF_TAG_REGEX = /\{ref (?<reference_id>\d+)\}/

  MISSING_OR_UNMISSING_TAG_REGEX = /\{(?:missing|unmissing)(?:[0-9])? (?<hardcoded_name>.*?)\}/
  MISSING_TAG_REGEX = /\{missing[0-9]? (?<hardcoded_name>.*?)\}/
  MISSING_TAG_START = "{missing"
  UNMISSING_TAG_REGEX = /\{unmissing (?<hardcoded_name>.*?)\}/
  MISSPELLING_TAG_REGEX = /\{misspelling (?<hardcoded_name>.*?)\}/

  HIDDENNOTE_TAG_REGEX = /\{hiddennote (?<note_content>.*?)\}/

  module RecordToTagRegex
    module_function

    def taxon taxon
      "{(tax|taxac) #{taxon.id}}"
    end

    def protonym protonym
      "{(pro|proac|prott) #{protonym.id}}"
    end

    def reference reference
      "{ref #{reference.id}}"
    end
  end

  module RecordToTag
    module_function

    def reference_to_ref_tag reference
      "{ref #{reference.id}}"
    end
  end

  module_function

  def to_ref_tag reference
    "{ref #{reference.id}}"
  end

  def extract_ids_from_tax_tags taxt
    taxt.scan(TAX_TAG_REGEX).flatten.compact.map(&:to_i)
  end

  def extract_ids_from_tax_or_taxac_tags taxt
    taxt.scan(TAX_OR_TAXAC_TAG_REGEX).flatten.map(&:to_i)
  end

  def extract_ids_from_ref_tags taxt
    taxt.scan(REF_TAG_REGEX).flatten.compact.map(&:to_i)
  end
end
