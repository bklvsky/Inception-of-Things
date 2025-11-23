export INSTALL_K3S_EXEC="agent --server=https://192.168.56.110:6443 --token-file=/vagrant/confs/master-node-token --node-ip=192.168.56.111";
      curl -sfL https://get.k3s.io | sh -;
      mkdir -p /etc/rancher/k3s;
      cp /vagrant/confs/k3s.yaml /etc/rancher/k3s/k3s.yaml;  