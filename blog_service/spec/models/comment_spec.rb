require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:body) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe 'factory' do
    it 'creates a valid comment' do
      comment = build(:comment)
      expect(comment).to be_valid
    end

    it 'creates a comment with associated user and post' do
      comment = create(:comment)
      expect(comment.user).to be_present
      expect(comment.post).to be_present
    end
  end
end
