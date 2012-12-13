class XactionsController < ApplicationController
  # GET /xactions
  # GET /xactions.json
  def index
	before_filter :authenticate
	before_filter :correct_user

	@account = current_user().account
    @xactions = Xaction.find_by_primary(current_user().id)

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @xactions }
    end
  end

  # GET /xactions/1
  # GET /xactions/1.json
  def show
	user = current_user()

    @xaction = Xaction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      #format.json { render json: @xaction }
    end
  end

  # GET /xactions/new
  # GET /xactions/new.json
  def new
    @xaction = Xaction.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @xaction }
    end
  end

  # GET /xactions/1/edit
  def edit
    @xaction = Xaction.find(params[:id])
  end

  # POST /xactions
  # POST /xactions.json
  def create
    @xaction = Xaction.new(params[:xaction])

    respond_to do |format|
      if @xaction.save
        format.html { redirect_to @xaction, notice: 'Xaction was successfully created.' }
        format.json { render json: @xaction, status: :created, location: @xaction }
      else
        format.html { render action: "new" }
        format.json { render json: @xaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /xactions/1
  # PUT /xactions/1.json
  def update
    @xaction = Xaction.find(params[:id])

    respond_to do |format|
      if @xaction.update_attributes(params[:xaction])
        format.html { redirect_to @xaction, notice: 'Xaction was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @xaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /xactions/1
  # DELETE /xactions/1.json
  def destroy
    @xaction = Xaction.find(params[:id])
    @xaction.destroy

    respond_to do |format|
      format.html { redirect_to xactions_url }
      format.json { head :no_content }
    end
  end
end
