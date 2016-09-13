use_inline_resources if defined?(use_inline_resources)

# Support whyrun
def whyrun_supported?
  true
end

action :upsert do
  client = get_client.use(@new_resource.database)

  if @current_resource.exists
    converge_by("Update #{ @new_resource }") do
      Chef::Log.info "#{ @new_resource } already exists in database #{ @new_resource.database } - updating."
      client.database.users.update(@new_resource.username,
                                   :password => @new_resource.password,
                                   :roles => @new_resource.roles,
                                   :database => @new_resource.database)
    end
  else
    converge_by("Create #{ @new_resource }") do
      Chef::Log.info "Creating #{ @new_resource } in database #{ @new_resource.database }"
      client.database.users.create(@new_resource.username,
                                   :password => @new_resource.password,
                                   :roles => @new_resource.roles,
                                   :database => @new_resource.database)

    end
  end
end

action :delete do
  client = get_client.use(@new_resource.database)

  if @current_resource.exists
    converge_by("Delete #{ @new_resource }") do
      Chef::Log.info "#{ @new_resource } deleting."
      client.database.users.delete(@new_resource.username)
    end
  else
    Chef::Log.info "#{ @new_resource } does not exists."
  end
end

def get_client
  require 'rubygems'
  require 'mongo'

  config = node['mongodb3']['config']['mongod']
  client = Mongo::Client.new(
      'mongodb://%s:%s' % ['127.0.0.1', config['net']['port']],
      :database => 'admin',
      :connect => :direct
  )

  if config['security']['authorization'] == 'enabled'
    admin = node['mongodb3']['admin']

    if admin['username'] and admin['password']
      client = client.with(user: admin['username'], password: admin['password'])
    elsif
      raise 'Authorization is enabled but admin credentials are not provided.'
    end
  end

  client
end

def load_current_resource
  @current_resource = Chef::Resource::Mongodb3User.new(@new_resource.name)
  @current_resource.username(@new_resource.username)
  @current_resource.password(@new_resource.password)
  @current_resource.database(@new_resource.database)
  @current_resource.roles(@new_resource.roles)

  client = get_client

  begin
    count = client.database['system.users'].find(:user => @new_resource.username,
                                                 :db => @new_resource.database).count()

    Chef::Log.debug "#{ count } #{@new_resource.username} users existing in database #{@new_resource.database}."

    @current_resource.exists = count > 0
  ensure
    client.close
  end
end
