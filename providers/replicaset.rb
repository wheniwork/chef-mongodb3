action :configure do
  members = @new_resource.members
  Chef::Log.info "Configuring replica set with #{members.length} member(s)"

  validate_members_list(members)

  unless already_initiated?(members)
    initilize_replicaset
  else
    reconfigure_replicaset
  end
end

def validate_members_list(members)
  raise "You have to pass in at least one member" if members.empty?

  unless (non_hash_members = members.reject{|n| n.is_a?(Hash)}).empty?
    raise "Some of the member configuations are not hashes:\n#{non_hash_members.inspect}"
  end

  unless (incomplete_members = members.reject{|n| n.key?('_id') && n.key?('host')}).empty?
    raise "Some of the members are missing an '_id' or 'host' key:\n#{incomplete_members.inspect}"
  end

  unless (invalid_hosts = members.reject{|n| n['host'] =~ /^[a-z0-9\-\.]+:\d+$/}).empty?
    raise "Some of the member 'host' settings are the wrong format:\n#{invalid_hosts.inspect}"
  end
end


def already_initiated?(members)
  Chef::Log.info 'Checking to see if replica set is initialized'

  replica_set_initiated = false

  if members.length == 1
    client = create_single_node_client

    begin
      client.command({'replSetGetStatus' => 1})
      Chef::Log.info 'Replica set is already initialized'
      replica_set_initiated = true
    rescue ::Mongo::Error::OperationFailure => ex
      # unless it's telling us to initiate the replica set
      unless ex.message.include? 'no replset config has been received'
        raise # re-raise the error - we want to know about it
      end
      Chef::Log.info 'Replica set is NOT initialized'
    ensure
      client.close if client
    end
  else
    begin
      client = create_replica_set_client
      client.command({'replSetGetStatus' => 1})
      replica_set_initiated = true
    rescue ::Mongo::Error::OperationFailure => ex
      # unless it's telling us that these members don't form a replica set
      unless ex.message.include? 'Cannot connect to a replica set using provided hosts'
        raise # re-raise the error - we want to know about it
      end
    rescue ::Mongo::Error::NoServerAvailable => ex
      Chef::Log.info 'Replica set is NOT initialized'
    ensure
      client.close if client
    end
  end

  replica_set_initiated
end

def initilize_replicaset
  Chef::Log.info 'Initializing replica set...'

  replica_set_config = Hash.new
  replica_set_config['_id'] =  @new_resource.name
  replica_set_config['members'] = @new_resource.members

  begin
    client = create_single_node_client
    client.command({'replSetInitiate' => replica_set_config})
    Chef::Log.info "Replica set '#{@new_resource.name}' initialized!"
  rescue ::Mongo::Error::OperationFailure => ex
    raise ex unless ex.message.include? 'already initialized'
    Chef::Log.warn 'Replica set already initialized'
  ensure
    client.close if client
  end

  begin
    client = create_replica_set_client
    client.command({'replSetGetStatus' => 1})
    Chef::Log.info "Replica set is up and running!"
  ensure
    client.close if client
  end

  @new_resource.updated_by_last_action(true)
end

def reconfigure_replicaset
  Chef::Log.info "Connecting to existing replica set"
  client = create_replica_set_client

  Chef::Log.info "Getting current replica set config"
  current_config = client.use('local')['system.replset'].find({"_id" => @new_resource.name}).limit(1).first
  current_members = current_config['members']

  Chef::Log.info "Generating new replica set config"
  new_config = Hash.new
  new_config['_id'] = @new_resource.name
  new_config['version'] = current_config['version'] + 1
  new_config['members'] = @new_resource.members

  Chef::Log.info "Comparing new config to old config"
  diff = get_members_config_diff(current_members, new_config['members'])

  unless diff.empty?
    Chef::Log.info "Replica set configuration changed - current config:\n#{current_config.inspect}\nnew config:\n#{new_config.inspect}"
    Chef::Log.info "Updating replica set configuration..."

    client.command({'replSetReconfig' => new_config})

    Chef::Log.info "Replica set configuration updated."
    @new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Replica set configuration identical - nothing to do"
  end
end

def get_members_config_diff(existing, desired)
  differences = []
  existing.each do |existing_member|
    desired.each do |desired_member|
      if desired_member['host'] == existing_member['host']
        desired_member.each do |key, value|
          unless desired_member[key] == existing_member[key]
            differences.push("#{existing_member['host']}: server #{key}=#{existing_member[key]} != new #{key}=#{desired_member[key]}")
          end
        end
      end
    end

  end

  existing_hosts = existing.collect{|m| m['host']}
  desired_hosts = desired.collect{|m| m['host']}
  new_members = desired_hosts.reject{|x| existing_hosts.include? x}

  new_members.each do |new_member|
    differences.push("Found new member: #{new_member}")
  end

  differences
end

def create_single_node_client
  require 'rubygems'
  require 'mongo'

  config = node['mongodb3']['config']['mongod']
  client = Mongo::Client.new(
      'mongodb://%s:%s' % [config['net']['bindIp'] || '127.0.0.1', config['net']['port']],
      :database => 'admin',
      :connect => :direct
  )

  if config['security']['authorization'] == 'enabled'
    client = authorize_client(client)
  end

  client
end

def create_replica_set_client
  require 'rubygems'
  require 'mongo'

  config = node['mongodb3']['config']['mongod']
  client = Mongo::Client.new(
      @new_resource.members.collect{|n| "#{n['host']}"},
      :database => 'admin',
      :connect => :replica_set,
      :replica_set => @new_resource.name
  )

  if config['security']['authorization'] == 'enabled'
    client = authorize_client(client)
  end

  client
end

def authorize_client(client)
  Chef::Log.info 'Authorizing connection with admin credentials.'
  admin = node['mongodb3']['admin']

  if admin['username'] and admin['password']
    client = client.with(user: admin['username'], password: admin['password'])
  elsif
  raise 'Authorization is enabled but admin credentials are not provided.'
  end

  client
end
