
class TransactionsController < ApplicationController
	before_filter :authenticate
	before_filter :correct_user, :only => [:edit, :update]
	before_filter :admin_user, :only => :destroy

  # GET /transactions
  # GET /transactions.json
  def index

	data = format_transaction_data_for(current_user)
	@party_classes = data.nil? ? nil : data[0]
	@transaction_data = data.nil? ? nil : data[1]

    respond_to do |format|
      format.html
      format.json { render json: @transactions }
    end
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
    @trans = Contract::Base.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trans }
    end
  end

  # GET /transactions/new
  # GET /transactions/new.json
  def new
    @trans = Contract::Base.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trans }
    end
  end

  # GET /transactions/1/edit
  def edit
    @trans = Contract::Base.find(params[:id])
  end

  # POST /transactions
  # POST /transactions.json
  def create
    @trans = Contract::Base.new(params[:trans])

    respond_to do |format|
      if @trans.save
        format.html { redirect_to @trans, notice: 'Transaction was successfully created.' }
        format.json { render json: @trans, status: :created, location: @trans }
      else
        format.html { render action: "new" }
        format.json { render json: @trans.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /transactions/1
  # PUT /transactions/1.json
  def update
    @trans = Contract::Base.find(params[:id])

    respond_to do |format|
      if @trans.update_attributes(params[:trans])
        format.html { redirect_to @trans, notice: 'Contract::Base was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trans.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @trans = Contract::Base.find(params[:id])
    @trans.destroy

    respond_to do |format|
      format.html { redirect_to transactions_url }
      format.json { head :no_content }
    end
  end

	#
	# For a given user, for each of the user's transactions,
	# create a hash of { <transaction> => {<party_class> => <party>} }.
	# Return an array containing [<all party classes>, <hash from above>]
	#
	def format_transaction_data_for(user)
		data = {} 

		user.contracts.each do |trans|
			party_list = {}
			trans.parties.each do |party|
				party_list[party.class] = party
			end
			data[trans] = party_list
		end

		klasses = data.inject(Set.new) do |set, trans_record|
			set + trans_record[1].keys
		end
		[klasses, data]
	end
end
