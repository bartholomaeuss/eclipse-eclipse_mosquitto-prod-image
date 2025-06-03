#!/bin/bash

show_help(){
    echo "Deploy basic ssh config to $HOME/.ssh/config."
    echo "usage: $0 [-d] [-i] [-r] [-t] [-u] [-h]"
    echo "  -d  dockerfile name"
    echo "  -i  image name"
    echo "  -r  remote host name"
    echo "  -t  image tag name"
    echo "  -u  remote host user name"
    echo "  -h  show help"
    exit 0
}

provide_container(){
    scp "${dockerfile}" "${user}@${remote}":"~/${dockerfile}"
    ssh -l "${user}" "${remote}" "docker network create homeautomation"
    ssh -l "${user}" "${remote}" "docker kill \$(docker ps -q --filter ancestor=${image}:${tag})"
    ssh -l "${user}" "${remote}" "docker build -t ${image}:${tag} -f ./${dockerfile} ."
    ssh -l "${user}" "${remote}" "docker run --network homeautomation -p 1883:1883 -v ~/mosquitto/config:/mosquitto/config -v ~/mosquitto/data:/mosquitto/data -v ~/mosquitto/log:/mosquitto/log --restart=unless-stopped ${image}:${tag}"
    exit 0
}

while getopts ":d:i:p:r:t:u:h" opt; do
  case $opt in
    d)
      dockerfile="$OPTARG"
      ;;
    i)
      image="$OPTARG"
      ;;
    r)
      remote="$OPTARG"
      ;;
    t)
      tag="$OPTARG"
      ;;
    u)
      user="$OPTARG"
      ;;
    h)
      show_help
      ;;
    \?)
      echo "unknown option: -$OPTARG" >&2
      show_help
      ;;
    :)
      echo "option requires an argument -$OPTARG." >&2
      show_help
      ;;
  esac
done

if [ "$#" -le 0 ]
then
  echo "script requires an option"
  show_help
fi

if [ -z "$image" ]
then
  echo "'-i' option is mandatory"
  show_help
fi

if [ -z "$remote" ]
then
  echo "'-r' option is mandatory"
  show_help
fi

if [ -z "$tag" ]
then
  echo "'-t' option is mandatory"
  show_help
fi

if [ -z "$user" ]
then
  echo "'-u' option is mandatory"
  show_help
fi

provide_container