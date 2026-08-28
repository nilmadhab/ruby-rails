require 'rails_helper'

RSpec.describe "Comments API", type: :request do
  let!(:user) { create(:user) }
  let!(:category) { create(:category) }
  let!(:post_record) { create(:post, user: user, category: category) }

  describe "POST /api/v1/posts/:post_id/comments" do
    let(:valid_params) { { comment: { body: "Great post!" } } }

    before { pp user }

    context "when authenticated" do
      it "creates a new comment" do
        expect {
          post "/api/v1/posts/#{post_record.id}/comments",
               params: valid_params,
               headers: auth_headers(user)
        }.to change(Comment, :count).by(1)
        puts JSON.pretty_generate(JSON.parse(response.body))
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['body']).to eq("Great post!")
      end

      it "associates comment with current user" do
        post "/api/v1/posts/#{post_record.id}/comments",
             params: valid_params,
             headers: auth_headers(user)

        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user.id)
      end

      it "associates comment with the post" do
        post "/api/v1/posts/#{post_record.id}/comments",
             params: valid_params,
             headers: auth_headers(user)

        json = JSON.parse(response.body)
        expect(json['post_id']).to eq(post_record.id)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/posts/#{post_record.id}/comments", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid parameters" do
      it "returns error for missing body" do
        post "/api/v1/posts/#{post_record.id}/comments",
             params: { comment: { body: "" } },
             headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Body can't be blank")
      end
    end

    context "with non-existent post" do
      it "returns not found" do
        post "/api/v1/posts/99999/comments",
             params: valid_params,
             headers: auth_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
