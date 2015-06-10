class Shopquik::TodoList < ActiveRecord::Base
  has_many :shopquik_todo_items, :class_name => 'Shopquik::TodoItem', foreign_key: 'shopquik_todo_list_id'

  validates_presence_of :title, :description
end