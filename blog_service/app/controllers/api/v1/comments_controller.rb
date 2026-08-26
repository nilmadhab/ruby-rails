class Api::V1::CommentsController < ApplicationController

    skip_before_action :authenticate_request, only: [:index]

    before_action :set_comment, only: [:show]

    def index
        @comments = Comment.includes(:user, :post).all
        render json: @comments, include: [:user, :post]
    end

    def show
        @comment = Comment.find(params[:id])
        render json: @comment, include: [:user, :post]
    end

    def set_comment
        @comment = Comment.find(params[:id])
    end


end
