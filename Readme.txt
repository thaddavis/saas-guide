p1 = Stripe::Plan.retrieve("plan-good")
p1 = Stripe::Plan.retrieve("plan-free")
p1 = Stripe::Plan.retrieve("plan-awesome")

Plan.create(:stripe_id => p1.id, :name => p1.name, :price => p1.amount, :interval => p1.interval)


#TO GET EVERYTHING BOOTED
redis-server /usr/local/etc/redis.conf
bundle exec sidekiq -C config/sidekiq.yml
