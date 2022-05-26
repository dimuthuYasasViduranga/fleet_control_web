#!/bin/bash
if command -v open &> /dev/null
then
    yarn build --report && open ./dist/report.html
else
    yarn build --report && start ./dist/report.html
fi