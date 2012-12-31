namespace :pibi do
  desc "populates user default payment methods"
  task :payment_methods => :environment do
    User.each { |u|
      if u.payment_methods.empty? then
        u.payment_methods.create({ name: "Cash" })
        u.payment_methods.create({ name: "Cheque" })
        u.payment_method = u.payment_methods.first
        u.save
      end
    }
  end
end
