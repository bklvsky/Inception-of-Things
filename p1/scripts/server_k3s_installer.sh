export INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644 --bind-address=192.168.56.110 --advertise-address=192.168.56.110 --node-ip=192.168.56.110";
      curl -sfL https://get.k3s.io |  sh -;
      if [[ ! -d "/vagrant/confs" ]]; then
          mkdir /vagrant/confs
      fi;
      rm -rf /vagrant/confs/* &>/dev/null;
      cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/master-node-token;
      cp /etc/rancher/k3s/k3s.yaml /vagrant/confs/k3s.yaml;            