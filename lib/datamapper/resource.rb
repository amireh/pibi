module DataMapper
  module Resource

    def all_errors
      errors.map { |e| e.first }
    end
    def collect_errors
      all_errors.join("\n")
    end

    # For some reason, resource.valid? keeps returning true
    # even if the validations failed, so we use a custom persisted?
    # method to validate the model's id which will be set only if
    # the object persisted.
    def persisted?
      !self.id.nil?
    end

    def refresh
      self.class.get(self.id)
    end

    alias_method :persistent?, :persisted?
  end
end
