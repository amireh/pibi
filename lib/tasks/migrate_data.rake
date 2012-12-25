$data_path = File.join(File.dirname(__FILE__), 'pibi')

namespace :pibi do
  desc "migrate from the live pibi data to the new structure"
  task :migrate => :environment do
    json = {}

    # migrate the users
    def name_from_email(email)
      email.split('@').first.sanitize
    end

    puts "Cleaning up old records."

    # CategoryTransaction.destroy
    # Transaction.destroy!
    # Category.destroy
    # Account.destroy
    User.destroy

    json[:users] = JSON.parse(File.read(File.join($data_path, 'pibi_users.json')))
    json[:stashes] = JSON.parse(File.read(File.join($data_path, 'pibi_stashes.json')))
    json[:tags] = JSON.parse(File.read(File.join($data_path, 'pibi_tags.json')))
    json[:transactions] = JSON.parse(File.read(File.join($data_path, 'pibi_transactions.json')))
    i = 0
    json[:users].each { |r|
      next if r['email'].include? 'tester'
      # break if i == 1
      # i += 1

      u = User.create({
        provider: 'pibi',
        name:     name_from_email(r['email']),
        nickname: name_from_email(r['email']),
        email:    r['email'],
        uid:      UUID.generate,
        password: nickname_salt,
        auto_nickname: true,
        auto_password: true
      })

      locate_account = lambda { |oid|
        json[:stashes].each { |sr|
          if sr['user_id']['$oid'] == oid then return sr end
        }
        nil
      }

      raise RuntimeError.new "#{u.collect_errors}" unless u

      puts u.inspect

      # update the account (we don't update the balance as it will be automatically
      # calculated when migrating the transactions)
      account_record = locate_account.call(r['_id']['$oid'])
      a = u.accounts.first
      a.update({
        label: account_record['name'],
        currency: account_record['currency']
      })
      a.save

      puts "Account: #{a.label}, (#{a.balance} #{a.currency})"

      # create the categories (called tags)
      tags = {}
      puts "Categories: "
      json[:tags].each { |tr|
        # skip tags not belonging to this account
        next unless tr['stash_id']['$oid'] == account_record['_id']['$oid']

        # create the tag & track it so we can attach txs to it later
        c = u.categories.create({ name: tr['name'] })
        tags[tr['_id']['$oid']] = c

        puts "\t#{c.name}"
      } # tag loop

      # finally, the transactions
      json[:transactions].each { |txr|
        # skip transactions not belonging to this account
        next unless txr['stash_id']['$oid'] == account_record['_id']['$oid']

        # is it a withdrawal or a deposit?
        # (keep in mind, recurring txs weren't implemented in the earlier version)
        # collection = case txr['type']
        #   when 'withdrawal' then Withdrawal
        #   when 'deposit'    then Deposit
        # end
        collection = a.send("#{txr['type']}s")

        tx = collection.create({
          account:    a,
          amount:     txr['amount'],
          currency:   txr['currency'],
          note:       txr['note'],
          occured_on: Time.at(txr['created_at']['$date'] / 1000)
        })

        raise RuntimeError.new "Unable to save transaction: #{txr.inspect}" unless tx.persisted?

        # puts tx.inspect

        # now we need to connect the tags/categories by looking up
        # each tag id referenced by this tx in the tags hash we created
        # above
        # puts "\t\tLinking tx to ##{txr['tag_ids'].size} categories"
        txr['tag_ids'].each { |tag_id|
          tx = tx.refresh
          tx.categories << tags[ tag_id['$oid'] ]
          tx.save
        }

        # tx.save

        if tx.categories.size != txr['tag_ids'].size then
          raise RuntimeError.new(
            "Transaction was supposed to be attached to ##{txr['tag_ids'].size}" +
            " categories, but was instead attached to ##{tx.categories.size}")
        end

        a = a.refresh
        puts "\t\t#{tx.type} -> #{tx.amount.to_f} #{tx.categories.collect { |c| c.name }} (#{tx.id})"
      }

      puts "#txs: #{a.transactions.count}"
      puts "#cats: #{u.categories.count}"
      puts "account: #{a.label}, (#{a.balance} #{a.currency})"
      puts "------"
    }

    # migrate accounts
  end
end
