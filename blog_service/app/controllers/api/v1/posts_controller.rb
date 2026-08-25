class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]

  def index
    @posts = Post.includes(:user, :category).all
    render json: @posts, include: [:user, :category]
  end

  def show
    render json: @post, include: [:user, :category]
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      render json: @post, include: [:user, :category], status: :created
    else
      render json: { errors: @post.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render json: @post, include: [:user, :category]
    else
      render json: { errors: @post.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :user_id, :category_id)
  end
end
