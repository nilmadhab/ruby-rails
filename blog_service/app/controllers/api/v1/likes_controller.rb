class Api::V1::LikesController < ApplicationController
    before_action :set_post

    def create
        @like = @post.likes.build(user: current_user)
        if @like.save
            render json: { message: "Post liked successfully." }, status: :created
        else
            render json: { errors: @like.errors.full_messages }, status: :unprocessable_entity
        end
    end 

    private

    def set_post
        @post = Post.find(params[:post_id])
    end

end
