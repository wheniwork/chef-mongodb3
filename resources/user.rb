actions :upsert, :delete
default_action :upsert

attribute :username, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String, :required => true
attribute :roles, :kind_of => Array, :required => true
attribute :database, :kind_of => String, :default => "admin"

attr_accessor :exists
