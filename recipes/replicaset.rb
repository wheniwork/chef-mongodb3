mongodb3_replicaset node['mongodb3']['config']['mongod']['replication']['replSetName'] do
  members node['mongodb3']['config']['replicaset']['members']
end
