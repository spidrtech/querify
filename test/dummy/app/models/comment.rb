class Comment < ActiveRecord::Base
  belongs_to :post, counter_cache: true
  belongs_to :author, counter_cache: true
end
