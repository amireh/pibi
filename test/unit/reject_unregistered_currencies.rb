a = Account.first
t = a.transactions.create({ amount: 5, type: 'Deposit', currency: 'FOO' })
puts t
puts t.valid?
puts t.collect_errors