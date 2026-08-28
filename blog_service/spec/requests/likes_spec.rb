require 'rails_helper'

RSpec.describe "Likes API", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:category) { create(:category) }
  let!(:post_record) { create(:post, user: other_user, category: category) }

  describe "POST /api/v1/posts/:post_id/like" do
    context "when authenticated" do
      it "likes a post" do
        expect {
          post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
        }.to change(Like, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['liked']).to be true
        expect(json['likes_count']).to eq(1)
      end

      it "associates like with current user" do
        post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)

        like = Like.last
        expect(like.user_id).to eq(user.id)
        expect(like.post_id).to eq(post_record.id)
      end

      it "prevents duplicate likes" do
        create(:like, user: user, post: post_record)

        expect {
          post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("User has already liked this post")
      end

      it "allows different users to like same post" do
        create(:like, user: other_user, post: post_record)

        expect {
          post "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
        }.to change(Like, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['likes_count']).to eq(2)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/posts/#{post_record.id}/like"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when post does not exist" do
      it "returns not found" do
        post "/api/v1/posts/99999/like", headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/posts/:post_id/like" do
    context "when authenticated" do
      context "when user has liked the post" do
        before do
          create(:like, user: user, post: post_record)
        end

        it "unlikes a post" do
          expect {
            delete "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
          }.to change(Like, :count).by(-1)

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['liked']).to be false
          expect(json['likes_count']).to eq(0)
        end

        it "only removes the current user's like" do
          create(:like, user: other_user, post: post_record)

          expect {
            delete "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)
          }.to change(Like, :count).by(-1)

          expect(Like.exists?(user: other_user, post: post_record)).to be true
          json = JSON.parse(response.body)
          expect(json['likes_count']).to eq(1)
        end
      end

      context "when user has not liked the post" do
        it "returns not found" do
          delete "/api/v1/posts/#{post_record.id}/like", headers: auth_headers(user)

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']).to eq("Like not found")
        end
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/posts/#{post_record.id}/like"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
