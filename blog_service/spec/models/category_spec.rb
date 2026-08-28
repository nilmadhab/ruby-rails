require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validations' do
    subject { build(:category) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid category' do
      category = build(:category)
      expect(category).to be_valid
    end
  end
end
