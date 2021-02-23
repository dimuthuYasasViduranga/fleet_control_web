tag=$(git describe --tag) 
image=hxreg.azurecr.io/fleet-control-ui:$tag
echo "building image => $image"
az acr login --name hxreg \
&& docker build \
  --no-cache \
  --build-arg site=test \
  --build-arg token=$(echo $HAULTRAX_GIT_TOKEN) \
  --build-arg commit=$(git rev-parse HEAD) \
  --build-arg branch=$(git rev-parse --abbrev-ref HEAD) \
  --build-arg creator=$(git config user.email) \
  --build-arg app_version=$tag \
  -t $image \
  -f release/Dockerfile . \
  \
&& docker push $image 
