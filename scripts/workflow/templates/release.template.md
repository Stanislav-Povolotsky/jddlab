[**jddlab** docker image version ${{ env.NEW_VERSION }}](https://hub.docker.com/r/${{ vars.DOCKER_IMAGE }}/tags?name=${{ env.NEW_VERSION }}).  

- run it with: `docker run -it --rm -v "$PWD:/work" ${{ vars.DOCKER_IMAGE }}:${{ env.NEW_VERSION }}` command.
- pull it from [Docker Hub](https://hub.docker.com/r/${{ vars.DOCKER_IMAGE }}): `docker pull ${{ vars.DOCKER_IMAGE }}:${{ env.NEW_VERSION }}`.

