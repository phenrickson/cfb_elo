load_cfb_calendar = function(seasons) {
        
        map_df(
                seasons,
                ~ cfbd_calendar(year = .x) 
        ) |>
                mutate(season = as.integer(season)) |>
                as_tibble()
        
}


load_cfb_games = function(years,
                          season_type = "both",
                          division = "fbs") {
        
        map_df(
                years,
                ~ cfbd_game_info(year = .x,
                                 season_type = season_type,
                                 division = division) |>
                        as_tibble()
        )
}

prep_cfb_games = function(games) {
        
        games |>
                mutate(game_id,
                       season,
                       week,
                       season_type,
                       game_date = as_datetime(start_date),
                       completed,
                       neutral_site,
                       conference_game,
                       attendance,
                       venue_id,
                       venue,
                       home_id,
                       home_team,
                       home_conference,
                       home_division,
                       home_points,
                       away_id,
                       away_team,
                       away_conference,
                       away_division,
                       away_points,
                       notes,
                       .keep = 'none') |>
                mutate(
                        across(
                                contains("division"),
                                ~ replace_na(.x, "missing")
                        )
                )
}
