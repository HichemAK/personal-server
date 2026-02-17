if docker --version; then
  echo "docker already installed!"
  exit 0
fi

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

