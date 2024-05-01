# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
        packages = c("tidyverse",
                     "cfbfastR"),
        format = "qs",
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source("src/data/load_data.R")
tar_source("src/models/calc_elo_ratings.R")

# Replace the target list below with your own:
list(
        tar_target(
                name = seasons,
                command = 
                        1869:cfbfastR:::most_recent_cfb_season()
        ),
        tar_target(
                name = calendar,
                command = 
                        load_cfb_calendar(seasons)
        ),
        tar_target(
                name = games,
                command = 
                        load_cfb_games(years = seasons)
        ),
        tar_target(
                name = games_prepared,
                command = 
                        games |>
                        prep_cfb_games()
        ),
        tar_target(
                name = elo,
                command = 
                        games_prepared |>
                        rename_all(toupper) |>
                        calc_elo_ratings(home_field_advantage = 75,
                                         reversion = 0,
                                         k = 35,
                                         v = 400,
                                         verbose = T)
        ),
        tar_target(
                name = elo_games,
                command = 
                        elo$game_outcomes
        ),
        tar_target(
                name = elo_teams,
                command = 
                        elo$team_outcomes
        )
)
