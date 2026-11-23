# frozen_string_literal: true

class CreateBeskarBannedIps < ActiveRecord::Migration[8.0]
  def change
    create_table :beskar_banned_ips do |t|
      t.string :ip_address, null: false
      t.string :reason, null: false
      t.text :details
      t.datetime :banned_at, null: false
      t.datetime :expires_at
      t.boolean :permanent, default: false, null: false
      t.integer :violation_count, default: 1, null: false
      t.text :metadata # Using text to store JSON (compatible with SQLite and PostgreSQL)

      t.timestamps
    end

    add_index :beskar_banned_ips, :ip_address, unique: true
    add_index :beskar_banned_ips, :banned_at
    add_index :beskar_banned_ips, :expires_at
    add_index :beskar_banned_ips, [:ip_address, :expires_at]
  end
end
