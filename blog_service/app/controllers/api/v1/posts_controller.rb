class Api::V1::PostsController < ApplicationController
  skip_before_action :authenticate_request, only: [:index, :show]
  before_action :set_post, only: [:show, :update, :destroy]

  def index
    @posts = Post.includes(:user, :category, :comments).all
    render json: @posts, include: [:user, :category, :comments]
  end

  def show
    render json: @post.as_json(include: {
      user: { only: [:id, :name, :email] },
      category: { only: [:id, :name] },
      comments: { include: { user: { only: [:id, :name] } } }
      #liked_by_current_user: @post.liked_by?(current_user) 
    }).merge(liked_by_current_user: @post.liked_by?(current_user), likes_count: @post.likes_count)
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      render json: @post, include: [:user, :category], status: :created
    else
      render json: { errors: @post.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @post.user_id != current_user.id
      render json: { error: "Not authorized" }, status: :forbidden
      return
    end

    if @post.update(post_params)
      render json: @post, include: [:user, :category]
    else
      render json: { errors: @post.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @post.user_id != current_user.id
      render json: { error: "Not authorized" }, status: :forbidden
      return
    end

    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :category_id)
  end
end
