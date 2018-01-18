class ContentChange < ApplicationRecord
  include SymbolizeJSON

  enum priority: { low: 0, high: 1 }

  def mark_processed!
    update!(processed_at: Time.now)
  end
end
