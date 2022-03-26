docker run \
  --name=obitoTest \
  -e PUID=1000 \
  -e PGID=1000 \
  -e PASSWORD=salut \
  -e SUDO_PASSWORD=salut \
  -e DB_REMOTE_ROOT_NAME=obito \
  -e DB_REMOTE_ROOT_PASS=salut \
  -e DOCKER_MODS="linuxserver/mods:code-server-extension-arguments" \
  -v /tmp/code-fre:/config \
-p 8443:8443 -p 80:80 \
--rm \
code-fre
