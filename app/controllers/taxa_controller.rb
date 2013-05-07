# coding: UTF-8
class TaxaController < ApplicationController
  before_filter :authenticate_catalog_editor
  skip_before_filter :authenticate_catalog_editor, if: :preview?

  def new
    @taxon = Genus.new
    create_object_web
    render :edit
  end

  def create
    @taxon = Genus.new
    begin
      create_object_web
      update_taxon params.dup[:taxon]
    rescue ActiveRecord::RecordInvalid
      render :edit and return
    end
    redirect_to catalog_url @taxon
  end

  def edit
    @taxon = Taxon.find params[:id]
    @show_elevate_to_species_button = @taxon.kind_of? Subspecies
    @add_taxon_button_text = 'Add Genus'
  end

  def update
    return elevate_to_species if params[:task_button_command] == 'elevate_to_species'

    @taxon = Taxon.find params[:id]
    begin
      update_taxon params.dup[:taxon]
    rescue ActiveRecord::RecordInvalid
      render :edit and return
    end
    redirect_to catalog_url @taxon
  end

  def elevate_to_species
    subspecies = Subspecies.find params[:id]
    old_species = subspecies.species
    subspecies.elevate_to_species
    redirect_to catalog_url subspecies
  end

  ###################
  def create_object_web
    @taxon.build_name unless @taxon.name
    @taxon.build_type_name unless @taxon.type_name
    @taxon.build_protonym unless @taxon.protonym
    @taxon.protonym.build_name unless @taxon.protonym.name
    @taxon.protonym.build_authorship unless @taxon.protonym.authorship
    @taxon
  end

  def update_taxon attributes
    Taxon.transaction do
      name_attributes                     = attributes.delete :name_attributes
      protonym_attributes                 = attributes.delete :protonym_attributes
      homonym_replaced_by_name_attributes = attributes.delete :homonym_replaced_by_name_attributes
      type_name_attributes                = attributes.delete :type_name_attributes

      update_name                 name_attributes
      update_epithet_status_flags attributes
      update_homonym_replaced_by  homonym_replaced_by_name_attributes
      update_protonym             protonym_attributes
      update_type_name            type_name_attributes if type_name_attributes

      @taxon.save!
    end
  end

  def update_epithet_status_flags attributes
    attributes[:incertae_sedis_in] = nil unless attributes[:incertae_sedis_in].present?
    @taxon.attributes = attributes
    @taxon.headline_notes_taxt = Taxt.from_editable attributes.delete :headline_notes_taxt
    if attributes[:type_taxt]
      @taxon.type_taxt = Taxt.from_editable attributes.delete :type_taxt
    end
  end

  def get_name_attributes attributes
    {genus_name: attributes[:epithet]}
  end

  def update_name attributes
    attributes[:name_id] = attributes.delete :id
    @taxon.attributes = attributes
  end

  def update_homonym_replaced_by attributes
    replacement_id = attributes[:id]
    replacement = replacement_id.present? ? Taxon.find_by_name_id(replacement_id) : nil
    @taxon.homonym_replaced_by = replacement
  end

  def update_protonym attributes
    attributes[:name_id] = attributes.delete(:name_attributes)[:id]
    update_protonym_authorship attributes.delete :authorship_attributes
    @taxon.protonym.attributes = attributes
  end

  def update_protonym_authorship attributes
    return unless @taxon.protonym.authorship
    attributes[:reference_id] = attributes.delete(:reference_attributes)[:id]
    return if attributes[:reference_id].blank? and @taxon.protonym.authorship.reference.blank?
    @taxon.protonym.authorship.attributes = attributes
    @taxon.protonym.authorship.attributes = attributes
  end

  def update_type_name attributes
    attributes[:type_name_id] = attributes.delete :id
    @taxon.attributes = attributes
  end

end
