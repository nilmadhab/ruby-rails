require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:category) }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid post' do
      post = build(:post)
      expect(post).to be_valid
    end

    it 'creates a post with associated user and category' do
      post = create(:post)
      expect(post.user).to be_present
      expect(post.category).to be_present
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated comments when post is destroyed' do
      post = create(:post)
      create_list(:comment, 3, post: post)

      expect { post.destroy }.to change(Comment, :count).by(-3)
    end
  end
end
