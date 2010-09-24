## Enable Logplex
  heroku logplex:enable
  
## Disable Logplex
  heroku logplex:disable

## Fetch logs
  heroku logplex

## Tail logs
  heroku logplex --tail

## Options

  heroku logplex --num 100  
  heroku logplex --ps dyno.1  
  heroku logplex --source app  