require 'dm-core'
require 'dm-types'

module DataMapper
  module Is
    module Lockable

      def is_lockable(options = {})
        include DataMapper::Is::Lockable::InstanceMethods

        options = {
          property: 'is_locked',
          locked_by_default: false,
          on: [],
          locked_message: "This #{self.class.name.to_s.downcase} is locked and can not be modified."
        }.merge(options)

        @message = options[:locked_message]

        property options[:property].to_sym, DataMapper::Property::Boolean, default: options[:locked_by_default]

        options[:on].each { |prop|
          valid_property = false
          properties.each { |dm_prop|
            if dm_prop.name == prop then
              valid_property = true
              break
            end
          }

          relationships.each { |dm_rel|
            if dm_rel.name == prop then
              valid_property = true
              break
            end
          }

          raise ArgumentError.new("No such property #{prop}.") unless valid_property

          validates_with_method prop, :reject_if_locked
        }
        [ :save, :update, :destroy ].each { |advice|
          before advice, :reject_if_locked
        }

      end

      module InstanceMethods
        def locked?
          self.refresh.is_locked
        end

        def lock!
          return if locked?

          self.refresh.update({ is_locked: true })

          true
        end

        def unlock!
          return unless locked?

          self.refresh.update!({ is_locked: false })

          true
        end

        def reject_if_locked(advice = nil)
          if persisted? && locked?
            errors.add :is_locked, @message
            throw :halt
          end

          true
        end

      end
    end
  end

  Model.append_extensions(Is::Lockable)
end