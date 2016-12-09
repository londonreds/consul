class EditDefaultsForEmails < ActiveRecord::Migration
  def up
    change_column :users, :email_on_comment, :boolean, default: true
    change_column :users, :email_on_comment_reply, :boolean, default: true
  end

  def down
    change_column :users, :email_on_comment, :boolean, default: false
    change_column :users, :email_on_comment_reply, :boolean, default: false
  end
end
