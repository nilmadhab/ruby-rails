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
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:likers).through(:likes) }
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

    it 'destroys associated likes when post is destroyed' do
      post = create(:post)
      create_list(:like, 3, post: post)

      expect { post.destroy }.to change(Like, :count).by(-3)
    end
  end

  describe '#likes_count' do
    it 'returns the number of likes' do
      post = create(:post)
      create_list(:like, 5, post: post)

      expect(post.likes_count).to eq(5)
    end

    it 'returns 0 when no likes' do
      post = create(:post)

      expect(post.likes_count).to eq(0)
    end
  end

  describe '#liked_by?' do
    let(:post) { create(:post) }
    let(:user) { create(:user) }

    it 'returns true when user has liked the post' do
      create(:like, user: user, post: post)

      expect(post.liked_by?(user)).to be true
    end

    it 'returns false when user has not liked the post' do
      expect(post.liked_by?(user)).to be false
    end

    it 'returns false when user is nil' do
      expect(post.liked_by?(nil)).to be false
    end
  end
end
