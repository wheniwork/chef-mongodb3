include_recipe 'mongodb3::mongo_gem'

users = [node['mongodb3']['admin']]
users.concat(node['mongodb3']['users'])

# Add each user specified in attributes
users.each do |user|
  mongodb3_user user['username'] do
    password user['password']
    roles user['roles']
    database user['database']
    action :upsert
  end
end
