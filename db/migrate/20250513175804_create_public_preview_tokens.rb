class CreatePublicPreviewTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :public_preview_tokens do |t|
      t.integer :issue_id
      t.string :value
      t.datetime :expires_at
    end
    add_index :public_preview_tokens, :issue_id
    add_index :public_preview_tokens, :value, unique: true
  end
end
