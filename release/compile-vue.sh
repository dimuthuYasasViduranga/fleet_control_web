echo Expected directory structure:
echo dispatcher-ui/
echo dispatch_phx/

yarn build

echo 'elixir - phoenix'
rm -fr ../dispatch_phx/priv/static/*
cp -a dist/. ../dispatch_phx/priv/static/
cd ../dispatch_phx
mix phx.digest

