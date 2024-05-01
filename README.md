# cfb_elo

calculate historical elo ratings for college football teams

## requirements

this project uses historical college football data loaded via the [cfbfastR](https://cfbfastr.sportsdataverse.org) package

in order to make use of this package, you must first obtain an API key:

1. follow the directions at https://collegefootballdata.com/key
2. add this API key to your R environment via `usethis::edit_r_environ()`

`CFBD_API_KEY = YOUR-API-KEY-HERE`