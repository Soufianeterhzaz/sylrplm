class DataDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :data, :binary
    add_column :documents, :content_type, :string
  end

  def self.down
    remove_column :documents, :content_type
    remove_column :documents, :data
  end
end
