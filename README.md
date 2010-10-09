## Add addon
  heroku addons:add logging:basic
  
## Remove addon
  heroku addons:remove logging:basic

## Fetch logs
  heroku logs

## Tail logs
  heroku logs --tail

## Options

  heroku logs --num 100  
  heroku logs --ps dyno.1  
  heroku logs --source app  