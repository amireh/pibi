# encoding: UTF-8

require 'addressable/uri'

class Hash
  # Removes a key from the hash and returns the hash
  def delete!(key)
    self.delete(key)
    self
  end

  # Merges self with another hash, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  #
  # Thanks to whoever made it.
  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end

    target
  end
end


class String
  def sanitize
    Addressable::URI.parse(self.downcase.gsub(/[[:^word:]]/u,'-').squeeze('-').chomp('-')).normalized_path
  end

  def is_email?
    (self =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/u) != nil
  end

  def pluralize(n)
    n == 1 ? "#{n} #{self}" : "#{n} #{self}s"
  end

  def vowelize
    Vowels.include?(self[0]) ? "an #{self}" : "a #{self}"
  end

  alias_method :blank?, :empty?

  private

  Vowels = ['a','o','u','i','e']
end

module Sinatra
  class Base
    class << self

      # for every DELETE route defined, a "legacy" GET equivalent route is defined
      # at @{path}/destroy for compatibility with browsers that do  not support
      # XMLHttpRequest and thus the DELETE HTTP method
      def delete(path, opts={}, &bk)
        route 'GET'   , "#{path}/destroy",  opts, &bk
        route 'DELETE', path,               opts, &bk
      end

    end
  end

  module Templates
    def erb(template, options={}, locals={})
      render :erb, template.to_sym, { layout: @layout }.merge(options), locals
    end

    def partial(template, options={}, locals={})
      erb template.to_sym, options.merge({ layout: false }), locals
    end
  end

  module ContentFor
    def yield_with_default(key, &default)
      unless default
        raise RuntimeError.new "Missing required default block"
      end

      if !content_for?(key)
        content_for(key.to_sym, &default)
      end

      yield_content(key)
    end

    def content_for?(key)
      content_blocks[key.to_sym].any?
    end
  end
end