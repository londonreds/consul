class FulltextIndexForProposals < ActiveRecord::Migration
  def up
    begin
      remove_index "proposals", name: "index_proposals_on_description"
    rescue
    end

    execute "create index index_proposals_on_description_full_text on proposals using gin(to_tsvector('english', description));"
  end

  def down
    remove_index "proposals", name: "index_proposals_on_description_full_text"
    add_index "proposals", ["description"], name: "index_proposals_on_description", using: :btree
  end
end
