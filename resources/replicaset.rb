actions :configure
default_action :configure

attribute :name, :kind_of => String, :name_attribute => true
attribute :members, :kind_of => Array, :required => true
