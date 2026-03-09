class SubscriptionsController < ApplicationController
  before_action -> { require_auth! }

  def new
    # Renders the upgrade page
  end

  def create
    unless current_local_user
      redirect_to root_path, alert: "Account not found. Please sign in again."
      return
    end

    # 1. Determine and Set Processor
    processor = (Rails.env.test? || Rails.env.development?) ? :fake_processor : :paddle_billing
    current_local_user.set_payment_processor processor, allow_fake: (processor == :fake_processor)

    # 2. Handle Test/Fake Bypass
    if current_local_user.payment_processor.processor == "fake_processor"
      current_local_user.payment_processor.subscribe(plan: "fake_plan")
      redirect_to recruiters_path, notice: "Upgrade successful! (Fake Processor)"
      return
    end

    # 3. Handle Real Paddle Billing Transaction
    # Ideally, Price ID comes from ENV
    price_id = ENV.fetch("PADDLE_PRICE_ID", "pri_01jkjd1642hg55k16k1730045f")

    # We need to create a transaction to get a transaction_id for Paddle.js
    transaction = Paddle::Transaction.create(
      items: [{ price_id: price_id, quantity: 1 }],
      customer_id: current_local_user.payment_processor.processor_id
    )

    @transaction_id = transaction.id
    render :checkout # Render a view that invokes Paddle.js
  rescue Pay::Error, StandardError => e
    Rails.logger.error "Pay Config: #{Pay.enabled_processors.inspect}"
    redirect_to new_subscription_path, alert: "Payment initialization error: #{e.message}"
  end
end
