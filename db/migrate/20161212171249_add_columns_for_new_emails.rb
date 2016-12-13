class AddColumnsForNewEmails < ActiveRecord::Migration
  def up
    add_column :users, :email_on_proposal_edit, :boolean, default: true
    add_column :users, :email_on_proposal_edit_as_commenter, :boolean, default: true
  end

  def down
    remove_column :users, :email_on_proposal_edit
    remove_column :user, :email_on_proposal_edit_as_commenter
  end
end
