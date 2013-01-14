# coding: UTF-8
require 'spec_helper'

describe Family do

  describe "Importing" do
    describe "When the database is empty" do
      it "should create the Family, Protonym, and Citation, and should link to the right Genus and Reference" do
        reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
        data =  {
          :protonym => {
            :family_or_subfamily_name => "Formicariae",
            :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
          },
          :type_genus => {
            :genus_name => 'Formica',
            :texts => [{:text => [{:phrase => ', by monotypy'}]}]
          },
          :history => ["Formicidae as family"]
        }

        family = Family.import(data).reload
        family.name.to_s.should == 'Formicidae'
        family.should_not be_invalid
        family.should_not be_fossil
        family.history_items.map(&:taxt).should == ['Formicidae as family']

        family.type_name.to_s.should == 'Formica'
        family.type_name.rank.should == 'genus'
        family.type_taxt.should == ', by monotypy'

        protonym = family.protonym
        protonym.name.to_s.should == 'Formicariae'

        authorship = protonym.authorship
        authorship.pages.should == '124'

        authorship.reference.should == reference
      end
      it "should save the note (when there's not a type taxon note)" do
        reference = FactoryGirl.create :article_reference, :bolton_key_cache => 'Latreille 1809'
        data =  {
          :protonym => {
            :family_or_subfamily_name => "Formicariae",
            :authorship => [{:author_names => ["Latreille"], :year => "1809", :pages => "124"}],
          },
          :type_genus => {:genus_name => 'Formica'},
          :note => [{:phrase=>"[Note.]"}],
          :history => ["Formicidae as family"]
        }

        family = Family.import(data).reload
        family.name.to_s.should == 'Formicidae'
        family.should_not be_invalid
        family.should_not be_fossil
        family.history_items.map(&:taxt).should == ['Formicidae as family']

        family.headline_notes_taxt.should == '[Note.]'

        protonym = family.protonym
        protonym.name.to_s.should == 'Formicariae'

        authorship = protonym.authorship
        authorship.pages.should == '124'

        authorship.reference.should == reference
      end
    end

    describe "When the family exists" do
      before do
        @eciton_name = create_name 'Eciton'
        @bolla_name = create_name 'Bolla'

        reference = FactoryGirl.create :article_reference,
          author_names: [Factory(:author_name, name: "Latreille")], citation_year: '1809', bolton_key_cache: 'Latreille 1809'
        @ref_taxt = "{ref #{reference.id}}"
        atta = create_genus 'Atta'
        @nam_taxt = "{nam #{atta.name.id}}"

        # create a Family
        name = FamilyName.create! name: 'Formicidae'
        @family = Family.create!(
          name: name,
          status: 'valid',
          headline_notes_taxt: @ref_taxt,
          type_taxt: @ref_taxt,
          type_fossil: false,
          type_name: @eciton_name
        )
        @history_item = @family.history_items.create! taxt: "1st history item"
        # and data that matches it
        @data = {
          fossil: false,
          status: 'valid',
          note: [{author_names: ["Latreille"], year: "1809"}],
          type_genus: {
            genus_name: 'Eciton',
            fossil: false,
            texts: [{author_names: ["Latreille"], year: "1809"}],
          },
          history: ['1st history item'],
        }
      end

      it "should compare, update and record value fields" do
        data = @data.merge fossil: true, status: 'synonym'

        family = Family.import data

        Update.count.should == 2

        update = Update.find_by_field_name 'fossil'
        update.class_name.should == 'Family'
        update.field_name.should == 'fossil'
        update.record_id.should == family.id
        update.before.should == '0'
        update.after.should == '1'
        family.fossil.should be_true

        update = Update.find_by_field_name 'status'
        update.before.should == 'valid'
        update.after.should == 'synonym'
        family.status.should == 'synonym'
      end

      it "should compare, update and record taxt" do
        data = @data.merge(
          note: [{genus_name: 'Atta'}],
          type_genus: {
            genus_name: 'Eciton',
            fossil: false,
            texts: [{genus_name: 'Atta'}],
          }
        )

        family = Family.import data

        Update.count.should == 2

        update = Update.find_by_field_name 'headline_notes_taxt'
        update.before.should == @ref_taxt
        update.after.should == @nam_taxt
        family.headline_notes_taxt.should == @nam_taxt

        update = Update.find_by_field_name 'type_taxt'
        update.before.should == @ref_taxt
        update.after.should == @nam_taxt
        family.type_taxt.should == @nam_taxt
      end

      it "should handle the type fields" do
        data = @data.merge(
          type_genus: {
            genus_name: 'Bolla',
            fossil: true,
            texts: [{genus_name: 'Atta'}]
          }
        )
        family = Family.import data
        Update.count.should == 3

        update = Update.find_by_field_name 'type_taxt'
        update.before.should == @ref_taxt
        update.after.should == @nam_taxt
        family.type_taxt.should == @nam_taxt

        update = Update.find_by_field_name 'type_fossil'
        update.before.should == '0'
        update.after.should == '1'
        family.type_fossil.should be_true

        update = Update.find_by_field_name 'type_name'
        update.before.should == 'Eciton'
        update.after.should == 'Bolla'
        family.type_name.should == @bolla_name
      end

      describe "Taxon history" do
        it "should replace existing items when the count is the same" do
          data = @data.merge(
            history: ['1st history item with change']
          )
          family = Family.import data

          Update.count.should == 1

          update = Update.find_by_field_name 'taxt'
          update.class_name.should == 'TaxonHistoryItem'
          update.field_name.should == 'taxt'
          update.record_id.should == family.history_items.first.id
          update.before.should == '1st history item'
          update.after.should == '1st history item with change'
          family.history_items.count.should == 1
          family.history_items.first.taxt.should == '1st history item with change'
        end
        it "should append new items" do
          data = @data.merge(
            history: ['1st history item', '2nd history item']
          )
          family = Family.import data

          Update.count.should == 1

          update = Update.find_by_field_name 'taxt'
          update.class_name.should == 'TaxonHistoryItem'
          update.record_id.should == family.history_items.second.id
          update.before.should == nil
          update.after.should == '2nd history item'
          family.history_items.count.should == 2
          family.history_items.first.taxt.should == '1st history item'
          family.history_items.second.taxt.should == '2nd history item'
        end
        it "should delete deleted ones" do
          data = @data.merge(history: [])
          original_id = @family.history_items.first.id

          family = Family.import data

          Update.count.should == 1

          update = Update.find_by_field_name 'taxt'
          update.class_name.should == 'TaxonHistoryItem'
          update.record_id.should == original_id
          update.before.should == nil
          update.after.should == nil
          family.history_items.count.should == 0
        end
      end
    end
  end

  describe "Statistics" do
    it "should return the statistics for each status of each rank" do
      family = FactoryGirl.create :family
      subfamily = FactoryGirl.create :subfamily
      tribe = FactoryGirl.create :tribe, subfamily: subfamily
      genus = FactoryGirl.create :genus, :subfamily => subfamily, :tribe => tribe
      FactoryGirl.create :genus, :subfamily => subfamily, :status => 'homonym', :tribe => tribe
      2.times {FactoryGirl.create :subfamily, :fossil => true}
      family.statistics.should == {
        :extant => {subfamilies: {'valid' => 1}, tribes: {'valid' => 1}, genera: {'valid' => 1, 'homonym' => 1}},
        :fossil => {subfamilies: {'valid' => 2}}
      }
    end
  end

  describe "Label" do
    it "should be the family name" do
      FactoryGirl.create(:family, name: FactoryGirl.create(:name, name: 'Formicidae')).name.to_html.should == 'Formicidae'
    end
  end

  describe "Genera" do
    it "should include genera without subfamilies" do
      family = create_family
      subfamily = create_subfamily
      genus_without_subfamily = create_genus subfamily: nil
      genus_with_subfamily = create_genus subfamily: subfamily
      family.genera.should == [genus_without_subfamily]
    end
  end

  describe "Subfamilies" do
    it "should include all the subfamilies" do
      family = create_family
      subfamily = create_subfamily
      family.subfamilies.should == [subfamily]
    end
  end

end
