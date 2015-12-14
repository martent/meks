class PlacementsController < ApplicationController
  before_action :set_refugee, only: [
    :new, :create, :edit, :move_out, :update, :move_out_update, :destroy]
  before_action :set_placement, only: [
    :edit, :move_out, :update, :move_out_update, :destroy]

  def index
    @placements = Placement.order('name')
  end

  def new
    @placement = @refugee.placements.new
  end

  def edit
  end

  def move_out
  end

  def create
    @placement = @refugee.placements.new(placement_params)

    if @placement.save
      redirect_to @refugee, notice: 'Placeringen registrerades'
    else
      render :new
    end
  end

  def update
    if @placement.update(placement_params)
      redirect_to @refugee, notice: 'Placeringen uppdaterades'
    else
      render :edit
    end
  end

  def move_out_update
    if @placement.update(placement_params)
      redirect_to @refugee, notice: 'Placeringen uppdaterades'
    else
      render :move_out
    end
  end

  private
    def set_refugee
      @refugee = Refugee.find(params[:refugee_id])
    end

    def set_placement
      @refugee = Refugee.find(params[:refugee_id])
      id = params[:id] || params[:placement_id]
      @placement = @refugee.placements.find(id)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def placement_params
      params.require(:placement).permit(
        :home_id, :refugee_id, :moved_in_at, :moved_out_at,
        :moved_out_reason_id, :comment
      )
    end
end