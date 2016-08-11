class PollsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_poll,          only: [:voting, :show, :edit, :update, :destroy]
  before_action :set_editing_time,  only: [:edit, :show, :index]

  # GET /polls
  # GET /polls.json
  # List of all polls in app
  def index
    case params[:show_me] = params[:show_me] || 'all'
    when 'all'
      @polls = Poll.all.order(state: :desc, created_at: :desc).page params[:page]
    when 'my'
      @polls = current_user.polls.order(state: :desc, created_at: :desc).page params[:page]
    end
  end
  
  # GET /polls/1
  # GET /polls/1.json
  def show
    if Poll.voted_by_user(@poll, current_user) || @poll.closed?
      @votes = []
      voted_users = []
      @poll.options.each_with_index do |option, index|
        # NOTE: option.votes.size if option.votes == nil raise exception. Have to use .to_a.
        # TODO: solve this problem
        @votes.push(option.votes.to_a.size)
        voted_users.push(option.votes.pluck(:user_id))
      end
      case @poll.poll_type
        when 'radio'
          @votes.push(@votes.inject(0){|sum,x| sum + x })
        when 'check_box'
          @votes.push(voted_users.uniq.count)
      end
    end
  end

  # GET /polls/new
  def new
    @poll = Poll.new
    @poll.options.build
  end

  # GET /polls/1/edit
  def edit
    if (DateTime.now.to_i - @poll.created_at.to_i) > @editing_time || !@poll.created?
      respond_to do |format|
        format.html { redirect_to @poll, alert: "Sorry! But you can't edit this poll." }
      end   
    end
  end

  # GET /polls/1/voting
  def voting
    Poll.voted_by_user(@poll, current_user) ? alert_string = "You've voted for this poll. " : alert_string = ''
    alert_string = alert_string + 'Poll is not opened.' unless @poll.opened?
    unless alert_string.blank?
      respond_to do |format|
        format.html { redirect_to @poll, alert: alert_string }
      end
    end
  end

  # POST /polls
  # POST /polls.json
  def create
    @poll = Poll.new(poll_params)
    @poll.user = current_user
    respond_to do |format|
      if @poll.save
        format.html { redirect_to @poll, notice: 'Poll was successfully created.' }
        format.json { render :show, status: :created, location: @poll }
      else
        format.html { render :new }
        format.json { render json: @poll.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /polls/1
  # PATCH/PUT /polls/1.json
  def update
    respond_to do |format|
      if @poll.update(poll_params)
        format.html { redirect_to @poll, notice: 'Poll was successfully updated.' }
        format.json { render :show, status: :ok, location: @poll }
      else
        format.html { render :edit }
        format.json { render json: @poll.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /polls/1
  # DELETE /polls/1.json
  def destroy
    @poll.destroy
    respond_to do |format|
      format.html { redirect_to polls_url, notice: "Poll \##{@poll.id} was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  private 

  # Set editing poll time limit
  def set_editing_time
    @editing_time = 10.hour
  end

  def set_poll
    @poll = Poll.find(params[:id])
  end

  def poll_params
    params.require(:poll).permit( :title, 
                                  :body, 
                                  :start, 
                                  :finish, 
                                  :state, 
                                  :poll_type, 
                                  :user_id, 
                                  :show_me, 
                                  :votes_count, 
                                  options_attributes: [:poll_option, :poll_id, :id, :_destroy]
                                  )
  end
end