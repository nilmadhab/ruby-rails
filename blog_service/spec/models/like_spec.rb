require 'rails_helper'

RSpec.describe Like, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe 'validations' do
    subject { build(:like) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:post_id).with_message("has already liked this post") }
  end

  describe 'uniqueness' do
    it 'prevents duplicate likes from same user on same post' do
      user = create(:user)
      post = create(:post)
      create(:like, user: user, post: post)

      duplicate = build(:like, user: user, post: post)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already liked this post")
    end

    it 'allows same user to like different posts' do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post)

      create(:like, user: user, post: post1)
      like2 = build(:like, user: user, post: post2)

      expect(like2).to be_valid
    end

    it 'allows different users to like same post' do
      user1 = create(:user)
      user2 = create(:user)
      post = create(:post)

      create(:like, user: user1, post: post)
      like2 = build(:like, user: user2, post: post)

      expect(like2).to be_valid
    end
  end

  describe 'factory' do
    it 'creates a valid like' do
      like = build(:like)
      expect(like).to be_valid
    end
  end
end
