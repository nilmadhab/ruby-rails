require 'rails_helper'

RSpec.describe "Posts API", type: :request do
  let!(:user) { create(:user) }
  let!(:category) { create(:category) }
  let!(:posts) { create_list(:post, 3, user: user, category: category) }

  describe "GET /api/v1/posts" do
    it "returns all posts" do
      get "/api/v1/posts"
      expect(response).to have_http_status(:ok)
      #debugger
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end

    it "includes user and category" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      expect(json.first['user']).to be_present
      expect(json.first['category']).to be_present
    end

    it "does not require authentication" do
      get "/api/v1/posts"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/posts/:id" do
    let(:post_record) { posts.first }

    it "returns a single post" do
      get "/api/v1/posts/#{post_record.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(post_record.id)
      expect(json['title']).to eq(post_record.title)
    end

    it "includes nested user, category, and comments" do
      create(:comment, post: post_record, user: user)

      get "/api/v1/posts/#{post_record.id}"

      json = JSON.parse(response.body)
      expect(json['user']).to be_present
      expect(json['category']).to be_present
      expect(json['comments']).to be_present
    end

    it "does not require authentication" do
      get "/api/v1/posts/#{post_record.id}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/posts" do
    let(:valid_params) do
      { post: { title: "New Post", body: "Post content", category_id: category.id } }
    end

    context "when authenticated" do
      it "creates a new post" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: auth_headers(user)
        }.to change(Post, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['title']).to eq("New Post")
        expect(json['user']['id']).to eq(user.id)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/posts", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid parameters" do
      it "returns error for missing title" do
        post "/api/v1/posts",
             params: { post: { body: "Content", category_id: category.id } },
             headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']['title']).to include("can't be blank")
      end
    end
  end

  describe "PATCH /api/v1/posts/:id" do
    let(:post_record) { create(:post, user: user, category: category) }

    context "when authenticated as owner" do
      it "updates the post" do
        patch "/api/v1/posts/#{post_record.id}",
              params: { post: { title: "Updated Title" } },
              headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['title']).to eq("Updated Title")
      end
    end

    context "when authenticated as different user" do
      let(:other_user) { create(:user) }

      it "returns forbidden" do
        patch "/api/v1/posts/#{post_record.id}",
              params: { post: { title: "Hacked" } },
              headers: auth_headers(other_user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/posts/#{post_record.id}",
              params: { post: { title: "Updated" } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    let!(:post_record) { create(:post, user: user, category: category) }

    context "when authenticated as owner" do
      it "deletes the post" do
        expect {
          delete "/api/v1/posts/#{post_record.id}", headers: auth_headers(user)
        }.to change(Post, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when authenticated as different user" do
      let(:other_user) { create(:user) }

      it "returns forbidden" do
        delete "/api/v1/posts/#{post_record.id}", headers: auth_headers(other_user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/posts/#{post_record.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
