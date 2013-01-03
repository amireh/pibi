# require 'sinatra/base'
# require 'datamapper/is/locatable'

# module Sinatra
#   module Locator

#     module Helpers
#       def url_for(*items)
#         path = []

#         options = {}
#         options = items.pop if items.last.is_a?(Hash)

#         items.each { |r|
#           next if r == :index # because the :index action appends no suffix
#           next if !r.respond_to?(:is_a?) # some objects aren't type-queriable

#           if r.is_a?(DataMapper::Resource) && r.respond_to?(:url_for)
#             path << r.url_for(options)
#           elsif r.is_a?(DataMapper::Associations::OneToMany::Collection) || r.is_a?(Class)
#             # build a temporary resource and see if it Is::Locatable
#             resource = r.new
#             if resource.respond_to?(:url_for)
#               path << url_for(resource, options).split('/')[1..-1]
#             end
#           elsif r.is_a?(Symbol) || r.is_a?(String)
#             path << r
#           else
#             puts "WARN: unknown path item: #{r} #{r.class}"
#           end
#         }

#         "/#{path.join('/')}"
#       end
#     end

#     def self.registered(app)
#       app.helpers Locator::Helpers
#     end

#   end # Locator module

#   register Locator
# end # Sinatra module
