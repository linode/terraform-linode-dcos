bootstrap_url: http://${bootstrap}:4040
cluster_name: ${cluster_name}
exhibitor_storage_backend: zookeeper
exhibitor_zk_hosts: ${bootstrap}:2181
exhibitor_zk_path: /${cluster_name}
log_directory: /genconf/logs
master_discovery: static
master_list: ${master_ips}
resolvers:
- 1.1.1.1
- 1.0.0.1
