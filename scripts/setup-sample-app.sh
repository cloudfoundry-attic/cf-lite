#!/bin/bash

set -ex

  repeat() {
    set +e
    for i in 1 2 3 4 5; do
      "$@"
      if [ $? -eq 0 ] ; then
        break
      fi
      sleep 10
    done
    set -e
  }

main(){
  repeat sudo -u ubuntu cf api --skip-ssl-validation https://api.10.244.0.34.xip.io
  sudo -u ubuntu cf auth admin admin

  set +e
  sudo -u ubuntu cf create-org sample-org
  sudo -u ubuntu cf target -o sample-org
  sudo -u ubuntu cf create-space sample-space
  set -e

  sudo -u ubuntu cf target -o sample-org -s sample-space

  #install_docker

  #sudo apt-get -y install apparmor
  #docker run -d --name cf-containers-broker  --publish 100:80  --volume /var/run:/var/run frodenas/cf-containers-broker

  install_sample_app

  set +e
  #repeat cf create-service-broker docker-broker containers secret http://cf-containers-broker.192.168.54.4.xip.io:100
  #cf enable-service-access postgresql93
  #cf create-service postgresql93 free postgres
  # cf bind-service spring-music postgres
  # cf restart spring-music
  set -e

  sudo -u ubuntu cf scale spring-music -i 2
}


install_docker(){
  curl -sSL https://get.docker.com/ubuntu/ | sudo sh
}

install_sample_app(){
  sudo apt-get -y install default-jdk

  sudo -u ubuntu git clone https://github.com/cloudfoundry-samples/spring-music.git
  cd spring-music
  sudo -u ubuntu ./gradlew assemble
  sudo -u ubuntu cf push spring-music
}

main


