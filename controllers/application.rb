module Pibi
  class << self
    def salt(pepper = "")
      pepper = Random.rand(12345 * 1000).to_s if pepper.empty?
      Base64.urlsafe_encode64( pepper + Random.rand(1234).to_s + Time.now.to_s)
    end
  end
end