#!/bin/bash
set -euxo pipefail #에러날 시 스크립트 종료

#초기 변수 선언
EXTRA_INSTALL="net-tools vim"

function disable_ipv6 { #ipv6 비활성화
  echo -e 'net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv4.ip_forward=1' | tee -a /etc/sysctl.conf
  sysctl -p
}

function dependency { #타임존 설정 후 의존성 설치
  timedatectl set-timezone Asia/Seoul
  apt-get update
  apt-get upgrade -y
  apt-get install -y $EXTRA_INSTALL
}

function install_docker { #docker 설치
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"$${UBUNTU_CODENAME:-$${VERSION_CODENAME}}\") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

function install_portainer_agent { #portainer agent 설치
  local WORK_DIR="/root/docker/portainer"
  mkdir -p $WORK_DIR
  cd $WORK_DIR
  wget -O $WORK_DIR/docker-compose.yml https://raw.githubusercontent.com/gitryk/oci_iac/refs/heads/main/portainer/agent/docker-compose.yml

  docker compose up -d 
}

disable_ipv6
dependency
install_docker
install_portainer_agent

set +e #어떤 에러가 발생하더라도 cloud-init 결과물을 홈 디렉토리에 생성하도록 하기
install -o ubuntu -g ubuntu -m 644 /var/log/cloud-init-output.log /home/ubuntu/init_log.txt || true
set -e
