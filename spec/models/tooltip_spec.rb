# frozen_string_literal: true

require 'rails_helper'

describe Tooltip do
  it { is_expected.to be_versioned }

  describe 'validations' do
    describe "#key" do
      describe 'uniqueness' do
        before { create :tooltip }

        it { is_expected.to validate_uniqueness_of(:key).ignoring_case_sensitivity }
      end

      it { is_expected.to validate_presence_of :key }
      it { is_expected.to validate_presence_of :scope }
      it { is_expected.to validate_presence_of :text }

      it { is_expected.to allow_value('namespace_key1').for :key }
      it { is_expected.not_to allow_value('name-space').for :key }
      it { is_expected.not_to allow_value('^namespace').for :key }
      it { is_expected.not_to allow_value('nämespace').for :key }
    end
  end
end
