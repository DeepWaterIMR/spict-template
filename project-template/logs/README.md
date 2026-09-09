# logs/

Render logs. Everything here except this README is git-ignored.

A long render — a benchmark with several candidates and their retrospectives — runs detached
with its output here:

```bash
screen -dmS spict-render bash -c 'Rscript docs/render.R > logs/render-$(date +%F-%H%M).log 2>&1'
```
