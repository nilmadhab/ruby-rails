require 'rails_helper'

RSpec.describe "Auth API", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      { name: "John Doe", email: "john@example.com", password: "password123" }
    end

    context "with valid parameters" do
      it "creates a new user and returns token" do
        expect {
          post "/api/v1/auth/register", params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json['user']['name']).to eq("John Doe")
        expect(json['user']['email']).to eq("john@example.com")
        expect(json['token']).to be_present
      end
    end

    context "with invalid parameters" do
      it "returns error for missing name" do
        post "/api/v1/auth/register", params: valid_params.except(:name)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "returns error for short password" do
        post "/api/v1/auth/register", params: valid_params.merge(password: "123")

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Password is too short (minimum is 6 characters)")
      end

      it "returns error for duplicate email" do
        create(:user, email: "john@example.com")

        post "/api/v1/auth/register", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Email has already been taken")
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      it "returns user and token" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq("test@example.com")
        expect(json['token']).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized for wrong password" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrong" }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Invalid email or password")
      end

      it "returns unauthorized for non-existent email" do
        post "/api/v1/auth/login", params: { email: "notfound@example.com", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    context "with valid token" do
      it "returns current user" do
        get "/api/v1/auth/me", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user']['id']).to eq(user.id)
        expect(json['user']['email']).to eq(user.email)
      end
    end

    context "without token" do
      it "returns unauthorized" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
