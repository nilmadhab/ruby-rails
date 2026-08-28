class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user

  validates :title, presence: true
  validates :body, presence: true

  def likes_count
    likes.count
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end
end
