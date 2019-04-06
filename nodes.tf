resource "scaleway_ip" "k8s_node_ip" {
  count = "${var.nodes}"
}

resource "scaleway_server" "k8s_node" {
  count          = "${var.nodes}"
  name           = "${terraform.workspace}-node-${count.index + 1}"
  image          = "${data.scaleway_image.xenial.id}"
  type           = "${var.server_type_node}"
  public_ip      = "${element(scaleway_ip.k8s_node_ip.*.ip, count.index)}"
  security_group = "${scaleway_security_group.node_security_group.id}"

//    volume {
//      size_in_gb = 40
//      type       = "l_ssd"
//    }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = "${file(var.private_key)}"
  }
  provisioner "file" {
    source      = "scripts/docker-install.sh"
    destination = "/tmp/docker-install.sh"
  }
  provisioner "file" {
    source      = "scripts/kubeadm-install.sh"
    destination = "/tmp/kubeadm-install.sh"
  }
  provisioner "file" {
    source      = "scripts/traefik-add-ip.sh"
    destination = "/tmp/traefik-add-ip.sh"
  }
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${scaleway_ip.k8s_master_ip.0.ip} \"cat /root/.kube/config\" | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${self.public_ip} \"mkdir -p /root/.kube; cat > /root/.kube/config\"",
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/docker-install.sh && /tmp/docker-install.sh ${var.docker_version}",
      "chmod +x /tmp/kubeadm-install.sh && /tmp/kubeadm-install.sh ${var.k8s_version}",
      "${data.external.kubeadm_join.result.command}",
      "apt install -y jq",
      "chmod +x /tmp/traefik-add-ip.sh && /tmp/traefik-add-ip.sh ${self.private_ip}",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "kubectl get pods --all-namespaces",
    ]

    on_failure = "continue"

    connection {
      type = "ssh"
      user = "root"
      host = "${scaleway_ip.k8s_master_ip.0.ip}"
    }
  }
}
