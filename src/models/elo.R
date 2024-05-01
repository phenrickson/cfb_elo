calc_elo_ratings <-
        function(games,
                 teams = list(),
                 team_seasons = list(),
                 home_field_advantage,
                 reversion,
                 k,
                 v,
                 verbose=t) {
                
                # define an empty tibble to store the game outcomes
                game_outcomes = tibble()
                
                # loop over games
                for(i in 1:nrow(games)) {
                        
                        ### get the individual game 
                        game = games[i,]
                        
                        ### get pre game elo ratings
                        # look for team in teams list
                        # if not defined, set to 1500 for fbs teams and 1200 for non fbs
                        
                        # get home elo rating
                        if (game$home_team %in% names(teams))
                        {home_rating = teams[[game$home_team]]} else 
                                if (game$home_division == 'fbs') {home_rating = 1500} else {home_rating = 1200}
                        
                        # get away elo rating
                        if (game$away_team %in% names(teams))
                        {away_rating = teams[[game$away_team]]} else 
                                if (game$away_division == 'fbs') {away_rating = 1500} else {away_rating = 1200}
                        
                        # check whether its a neutral site game to apply home field advantage adjustment
                        if (game$neutral_site==T) {add_home_field_advantage = 0} else 
                                if (game$neutral_site==F) {add_home_field_advantage = home_field_advantage}
                        
                        # check whether the team has already played in a season
                        # check whether the season of the game is the same season 
                        # as the current team season value
                        # if not, apply a mean reversion
                        
                        # set reversion amount
                        # home team
                        if (length(team_seasons[[game$home_team]]) ==0) {team_seasons[[game$home_team]] = game$season} else
                                if (game$season == team_seasons[[game$home_team]]) {home_rating = home_rating} else 
                                        if (
                                                (team_seasons[[game$home_team]] < game$season) & game$home_division == 'fbs'
                                        )
                                        {home_rating = ((reversion*1500)+ (1-reversion)*home_rating)} else
                                                if (
                                                        (team_seasons[[game$home_team]] < game$season) & game$home_division != 'fbs'
                                                )
                                                {home_rating = ((reversion*1200)+(1-reversion)*home_rating)}
                        
                        # away team
                        if (length(team_seasons[[game$away_team]]) ==0) {team_seasons[[game$away_team]] = game$season} else
                                if (game$season == team_seasons[[game$away_team]]) {away_rating = away_rating} else 
                                        if (
                                                (team_seasons[[game$away_team]] < game$season) & game$away_division == 'fbs'
                                        )
                                        {away_rating = ((reversion*1500)+ (1-reversion)*away_rating)} else
                                                if (
                                                        (team_seasons[[game$away_team]] < game$season) & game$away_division != 'fbs'
                                                )
                                                {away_rating = ((reversion*1200)+(1-reversion)*away_rating)}
                        
                        
                        ### recruiting
                        # get each team's
                        
                        ## get the score margin based on the home team
                        home_margin = game$home_points - game$away_points
                        
                        # define outcome
                        if (home_margin > 0) {home_outcome = 'win'} else
                                if (home_margin < 0) {home_outcome = 'loss'} else
                                        if (home_margin == 0) {home_outcome = 'tie'}
                        
                        if (home_margin > 0) {away_outcome = 'loss'} else
                                if (home_margin < 0) {away_outcome = 'win'} else
                                        if (home_margin == 0) {away_outcome = 'tie'}
                        
                        # get updated elo for both teams
                        new_elos = get_new_elos(home_rating,
                                                away_rating,
                                                home_margin,
                                                add_home_field_advantage,
                                                k,
                                                v)
                        
                        # add pre game elo ratings to the selected game
                        # do not include the adjustment for home advantage in the pre game
                        game$home_pregame_elo = home_rating
                        game$away_pregame_elo = away_rating
                        
                        # add pre game prob
                        game$home_prob = new_elos[3]
                        game$away_prob = new_elos[4]
                        
                        # add post game elo ratings to the selected game
                        game$home_postgame_elo = new_elos[1]
                        game$away_postgame_elo = new_elos[2]
                        
                        # get the score and game outcome
                        game$home_margin = home_margin
                        game$home_outcome = home_outcome
                        game$away_margin = -home_margin
                        game$away_outcome = away_outcome
                        
                        # update the list storing the current elo rating for each team
                        teams[[game$home_team]] = new_elos[1]
                        teams[[game$away_team]] = new_elos[2]
                        
                        # upaate the list storing the current team season
                        team_seasons[[game$home_team]] = game$season
                        team_seasons[[game$away_team]] = game$season
                        
                        # store 
                        game_outcomes = bind_rows(game_outcomes,
                                                  game)
                        
                        # log output
                        if (verbose== T) {cat("\r", i, "of", nrow(games), "games completed");  flush.console()}
                        
                }
                
                # create a table at the team level that is easy to examine the results
                team_outcomes = game_outcomes %>% 
                        select(game_id, 
                               season,
                               season_type,
                               week,
                               game_date,
                               home_team,
                               home_conference,
                               home_division,
                               home_points,
                               home_margin,
                               home_outcome,
                               home_pregame_elo,
                               home_postgame_elo,
                               away_team,
                               away_points) %>%
                        rename(opponent = away_team,
                               opponent_points = away_points) %>%
                        set_names(., gsub("home_", "", names(.))) %>%
                        bind_rows(.,
                                  game_outcomes %>% 
                                          select(game_id, 
                                                 season,
                                                 season_type,
                                                 week,
                                                 game_date,
                                                 away_team,
                                                 away_conference,
                                                 away_division,
                                                 away_points,
                                                 away_margin,
                                                 away_outcome,
                                                 away_pregame_elo,
                                                 away_postgame_elo,
                                                 home_team,
                                                 home_points) %>%
                                          rename(opponent = home_team,
                                                 opponent_points = home_points) %>%
                                          set_names(., gsub("away_", "", names(.)))) %>%
                        arrange(game_date) %>%
                        mutate(home_field_advantage = home_field_advantage,
                               reversion = reversion,
                               k = k,
                               v = v)
                return(list(
                        "game_outcomes" = game_outcomes,
                        "team_outcomes" = team_outcomes,
                        "team_seasons" = team_seasons,
                        "teams" = teams)
                )
                
        }

get_new_elos <-
        function(home_rating, 
                 away_rating,
                 home_margin,
                 home_field_advantage,
                 k,
                 v) {
                
                # get observed home score
                # if the home team wins, then home score = 1
                # if the home team loses, then home score = 0
                # in a tie, home score = 0.5
                if (home_margin > 0) {home_score = 1} else
                        if (home_margin < 0) {home_score = 0} else
                        {home_score = 0.5}
                
                # get observed away score, 1-home
                away_score = 1-home_score
                
                ## determine whether there is home field advantage
                
                ## get home and away expected scores
                # get expected home score based on the pre game rating and home field advantage
                home_expected_score = get_expected_score(home_rating + home_field_advantage,
                                                         away_rating,
                                                         v=v)
                
                
                # get expected away score based on pre game rating
                away_expected_score = get_expected_score(away_rating,
                                                         home_rating + home_field_advantage,
                                                         v=v)
                
                ## define margin of victory multiplier based on winner
                if (home_margin > 0) {
                        mov_multi = log(abs(home_margin)+1) * (2.2 / (((home_rating + home_field_advantage - away_rating)*0.001) + 2.2))
                } else if (home_margin <0) {
                        mov_multi = log(abs(home_margin)+1) * (2.2 / (((away_rating - home_rating + home_field_advantage)*0.001) + 2.2))
                } else {
                        mov_multi = 2.2*log(2)
                }
                
                ## update ratings
                # update home rating
                home_new_rating = home_rating + 
                        (mov_multi *
                                 k * 
                                 (home_score - home_expected_score))
                
                # update away rating
                away_new_rating = away_rating + 
                        (mov_multi *
                                 k * 
                                 (away_score - away_expected_score))
                
                return(c(home_new_rating,
                         away_new_rating,
                         home_expected_score,
                         away_expected_score))
        }

get_expected_score <-
        function(team_rating, opponent_rating, v=400) {
                
                return(1 / (1 + 10^((opponent_rating - team_rating) / v)))
        }

