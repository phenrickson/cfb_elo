# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
        packages = c("tidyverse",
                     "cfbfastR"),
        format = "qs"
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source("src/data/load_data.R")
tar_source("src/models/elo.R")
tar_source("src/models/assess.R")
tar_source("src/visualizations/plots.R")

# Replace the target list below with your own:
list(
        tar_target(
                name = seasons,
                command = 
                        1869:cfbfastR:::most_recent_cfb_season()
        ),
        tar_target(
                name = games,
                command = 
                        load_cfb_games(years = seasons)
        ),
        tar_target(
                name = historical_games,
                command = 
                        games |>
                        prep_cfb_games() |>
                        filter(completed == T)
        ),
        tar_target(
                name = elo_ratings,
                command = 
                        historical_games |>
                        calc_elo_ratings(home_field_advantage = 75,
                                         reversion = 0,
                                         k = 35,
                                         v = 400,
                                         verbose = T)
        ),
        tar_target(
                name = elo_games,
                command = 
                        elo_ratings$game_outcomes
        ),
        tar_target(
                name = elo_teams,
                command = elo_ratings$team_outcomes
        ),
        tar_target(
                name = elo_predictions,
                command = 
                        elo_games |>
                        add_elo_predictions()
        ),
        tar_target(
                name = metrics,
                command = elo_predictions |>
                        assess_predictions(),
                packages = c("yardstick")
        ),
        tar_target(
                name = calibration,
                command = 
                        elo_predictions |>
                        plot_calibration(),
                packages = c("probably")
        ),
        tar_target(
                name = spread_games,
                command = 
                        elo_games |>
                        add_spread_features()
        ),
        tar_target(
                name = spread_model,
                command = 
                        spread_games |>
                        model_spread()
        ),
        tar_target(
                name = spread_predictions,
                command = 
                        spread_model |>
                        augment(newdata = spread_games),
                packages = c("broom", "tune")
        ),
        tar_target(
                current_season_games,
                command = 
                        load_cfb_games(years = cfbfastR:::most_recent_cfb_season()) |>
                        prep_cfb_games(),
                cue = tar_cue_age(
                        current_season_games,
                        age = as.difftime(5, units = "days")
                )
        ),
        tar_render(
                report,
                "report.qmd"
        )
        
)
