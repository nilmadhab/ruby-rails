class Api::V1::HelloController < ApplicationController
  def index
    render json: { message: "Hello, World!" }
  end
end
