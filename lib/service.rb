# frozen_string_literal: true

# To make services callable like this:
# `ServiceObject[params]` instead of `ServiceObject.new(params).call`.

module Service
  def self.included base
    base.extend(ClassMethods)
  end

  module ClassMethods
    def [](...) # rubocop:disable Style/MethodDefParentheses
      new(...).call
    end
  end
end
