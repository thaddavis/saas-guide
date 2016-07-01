class SubscriptionsController < ApplicationController

  before_action :authenticate_user!

  def new
    @plans = Plan.all
  end

  def edit
    @account  = Account.find(params[:id])
    @plans = Plan.all
  end

  def create
    ap "Inside create in subscription"
    ap params
    ap current_user

    # Get the credit card details submitted by the form
    token = params[:stripeToken]
    plan = params[:plan][:stripe_id]
    email = current_user.email
    current_account = Account.find_by_email(current_user.email)
    customer_id = current_account.customer_id
    current_plan = current_account.stripe_plan_id

    if customer_id.nil?
      # Create a Customer
      @customer = Stripe::Customer.create(
        :source => token,
        :plan => plan,
        :email => email
      )

      subcriptions = @customer.subscriptions
      @subscribed_plan = subcriptions.data.find { |o| o.plan.id == plan }

    else
      # Customer already exists
      @customer = Stripe::Customer.retrieve(customer_id)
      @subscribed_plan = create_or_update_subscription(@customer, current_plan, plan)

    end

    # get current period end - this is a unix timestamp
    current_period_end = @subscribed_plan.current_period_end
    active_until = Time.at(current_period_end)

    save_account_details(current_account, plan, @customer.id, active_until)

    redirect_to :root, :notice => "Succesfully subcribed to plan: #{Plan.find_by_stripe_id(plan).name}"

    rescue => e
      redirect_to :back, :flash => { :error => e.message }

  end

  def index
    @account = Account.find_by_email(current_user.email)
  end

  def cancel_subscription
    #Fetch customer from Stripe
    email = current_user.email
    current_account = Account.find_by_email(current_user.email)
    customer_id = current_account.customer_id
    current_plan = current_account.stripe_plan_id

    if current_plan.blank?
      raise "No plan found to unsubscribe from"
    end

    customer = Stripe::Customer.retrieve(customer_id)
    #Get customer subscriptions's
    subscriptions = customer.subscriptions
    #Find specific subscription
    current_subscribed_plan = subscriptions.data.find { |o| o.plan.id == current_plan}
    if current_subscribed_plan.blank?
      raise "Subscription not found!!!"
    end
    #Delete specific subscription
    current_subscribed_plan.delete
    #Update account model
    save_account_details(current_account, "", customer_id, Time.at(0).to_datetime)

    @message = "Subscription cancelled successfully"

    rescue => e
      redirect_to "/subscriptions", :flash => { :error => e.message }
  end

  def update_card

  end

  def update_card_details
    #Take the token given by stripe and set it on the customer object
    ap "KKKKKKKKKKKKKKKK"
    ap "params"
    ap params

    token = params[:stripeToken]
    current_account = Account.find_by_email(current_user.email)

    ap "BBBBBBBBBBBBBBB"
    ap "customer _ account"
    ap current_account

    ap "token"
    ap token

    customer_id = current_account.customer_id
    #Get customer from Stripe
    customer = Stripe::Customer.retrieve(customer_id)

    ap "BBBBBBBBBBBBBBB"
    ap "customer"
    ap customer

    #Set new card token
    customer.source = token
    customer.save

    redirect_to "/subscriptions", :notice => "Card updated succesfully"

    rescue => e
      redirect_to :action => "update_card", :flash => { :notice => e.message }

  end

  def save_account_details(account, plan, customer_id, active_until)
    # Customer created with a valid subcription
    # So, update Account model
    account.stripe_plan_id = plan
    account.customer_id = customer_id
    account.active_until = active_until
    account.save!
  end

  def create_or_update_subscription(customer, current_plan, new_plan)
    subscriptions = customer.subscriptions
    #Get current subscription
    current_subscription = subscriptions.data.find { |o| o.plan.id == current_plan }

    if current_subscription.blank?
      #No Current Subscription
      #Maybe subscription was cancelled or Credit Card was declined
      #So create new subscription for existing customer
      subscription = customer.subscriptions.create( {:plan => new_plan})
    else
      #Existing subscription found
      #So an upgrade or downgrade is occuring
      current_subscription.plan = new_plan
      subscription = current_subscription.save
    end

    return subscription
  end
end
