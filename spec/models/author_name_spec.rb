require 'spec_helper'

describe AuthorName do
  it { is_expected.to be_versioned }
  it { is_expected.to validate_presence_of :author }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_uniqueness_of :name }

  describe "editing" do
    it "updates associated references when the name is changed" do
      author_name = create :author_name, name: 'Ward'
      reference = create :reference, author_names: [author_name]
      author_name.update name: 'Fisher'
      expect(reference.reload.author_names_string).to eq 'Fisher'
    end
  end

  describe "#last_name and #first_name_and_initials" do
    context "when there's only one word" do
      let(:author_name) { described_class.new name: 'Bolton' }

      it "simply returns the name" do
        expect(author_name.last_name).to eq 'Bolton'
        expect(author_name.first_name_and_initials).to be_nil
      end
    end

    context 'when there are multiple words' do
      let(:author_name) { described_class.new name: 'Bolton, B.L.' }

      it "separates the words" do
        expect(author_name.last_name).to eq 'Bolton'
        expect(author_name.first_name_and_initials).to eq 'B.L.'
      end
    end

    context 'when there is no comma' do
      let(:author_name) { described_class.new name: 'Royal Academy' }

      it "uses all words" do
        expect(author_name.last_name).to eq 'Royal Academy'
        expect(author_name.first_name_and_initials).to be_nil
      end
    end

    context 'when there are multiple commas' do
      let(:author_name) { described_class.new name: 'Baroni Urbani, C.' }

      it "uses all words before the comma" do
        expect(author_name.last_name).to eq 'Baroni Urbani'
        expect(author_name.first_name_and_initials).to eq 'C.'
      end
    end
  end
end
