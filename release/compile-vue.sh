echo Expected directory structure:
echo phx/
echo vue/

cd vue
yarn build

echo 'elixir - phoenix'
rm -fr ../phx/priv/static/*
cp -a dist/. ../phx/priv/static/
cd ../phx
mix phx.digest

