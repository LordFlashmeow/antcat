# frozen_string_literal: true

require 'rails_helper'

describe ArticleReference do
  describe 'relations' do
    it { is_expected.to belong_to(:journal).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :series_volume_issue }
  end

  describe "parsing fields from series_volume_issue" do
    let(:reference) { build_stubbed :article_reference }

    it "can extract volume and issue" do
      reference.series_volume_issue = "92(32)"
      expect(reference.volume).to eq '92'
      expect(reference.issue).to eq '32'
    end

    it "can extract the series and volume" do
      reference.series_volume_issue = '(10)8'
      expect(reference.series).to eq '10'
      expect(reference.volume).to eq '8'
    end

    it "can extract series, volume and issue" do
      reference.series_volume_issue = '(I)C(xix):129-131.'
      expect(reference.series).to eq 'I'
      expect(reference.volume).to eq 'C'
      expect(reference.issue).to eq 'xix'
    end
  end
end
