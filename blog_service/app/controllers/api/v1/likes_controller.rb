class Api::V1::LikesController < ApplicationController
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)
    if @like.save
      render json: like_response(true), status: :created
    else
      render json: { errors: @like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)
    if @like&.destroy
      render json: like_response(false)
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def like_response(liked)
    {
      liked: liked,
      likes_count: @post.likes.count
    }
  end
end
