plot_historical_elo <-
        function(elo_ratings,
                 highlight_team,
                 smooth = F) {
                
                elo_ratings$game_date = as.Date(elo_ratings$game_date)
                
                min_year = min(elo_ratings$season)
                min_date = as.Date(paste(min_year, "01", "01", sep="-"))
                max_year = max(elo_ratings$season)
                
                all_teams_data = elo_ratings %>%
                        filter(season > min_year) %>%
                        filter(division == 'fbs') 
                
                all_teams_median = all_teams_data %>%
                        summarize(median = median(postgame_elo)) %>%
                        pull(median)
                
                p = all_teams_data %>%
                        ggplot(aes(x=game_date,
                                   by = team,
                                   y= postgame_elo))+
                        geom_point(alpha = 0.004) +
                        geom_hline(yintercept = all_teams_median,
                                   linetype = 'dashed',
                                   color = 'grey60')+
                        annotate("text",
                                 x = min_date,
                                 y=all_teams_median + 50,
                                 size = 3,
                                 color = 'grey60',
                                 label = paste("fbs", "\n", "median"))
                
                # now add team data
                team_data = elo_ratings %>%
                        filter(season > min_year) %>%
                        filter(team %in% highlight_team) %>%
                        mutate(selected_team = highlight_team) %>%
                        group_by(team) %>%
                        mutate(team_label = case_when(game_date == max(game_date) ~ team)) %>%
                        ungroup()
                
                if(smooth == T ) {p = p + geom_line(data =team_data,
                                                    stat = 'smooth',
                                                    formula = 'y ~ x',
                                                    method = 'loess',
                                                    alpha =0.5,
                                                    span = 0.2,
                                                    lwd = 1.04)}
                else {p = p}
                
                out =  p + 
                        geom_point(data = team_data,
                                   alpha  =0.4)+
                        ggtitle(paste("historical elo rating for", paste(highlight_team, collapse="-")),
                                subtitle = str_wrap(paste('displaying postagme elo ratings for all fbs highlight_team from',
                                                          min_year, 'to present.'), 120))+
                        theme_minimal()+
                        theme(plot.title = element_text(hjust = 0.5, size = 16),
                              plot.subtitle =  element_text(hjust = 0.5),
                              strip.text.x = element_text(size = 12))+
                        guides(color = 'none')+
                        ylab("postgame elo rating")+
                        xlab("season (game date)")
                
                suppressWarnings(print(out))
                
        }

plot_team_elo = function(data,
                         fbs_median = 1580) {
        
        data$game_date = as.Date(data$game_date)
        
        label_game = function(data) {
                
                data |>
                        group_by(game_date,
                                 team,
                                 postgame_elo) |>
                        reframe(
                                label = paste(
                                        game_date,
                                        "\n",
                                        paste(team, opponent, sep = " - "),
                                        "\n",
                                        paste(
                                                paste(points, opponent_points, sep = " - "),
                                                outcome
                                        )
                                )
                        )
                
        }
        
        team_median = 
                median(data$postgame_elo, na.rm=T)
        
        team_high =
                data |>
                filter(postgame_elo == max(postgame_elo, na.rm = T)) |>
                label_game()
        
        team_low = 
                data |>
                filter(postgame_elo == min(postgame_elo, na.rm = T)) |>
                label_game()
        
        data |>
                ggplot(aes(x=game_date, y=postgame_elo, by = team))+
                geom_point(size = 0.5)+
                geom_line()+
                coord_cartesian(ylim = c(800, 2600))+
                geom_hline(
                        yintercept = fbs_median,
                        color = 'grey60',
                        linetype = 'dashed'
                )+
                annotate("text",
                         x = min(data$game_date),
                         y=fbs_median - 150,
                         size = 3,
                         color = "grey60",
                         label = paste("fbs", "\n", "median")
                )+
                geom_hline(
                        yintercept = team_median,
                        alpha = 0.8
                )+
                annotate("text",
                         x = min(data$game_date),
                         y=team_median +150,
                         size = 3,
                         label = paste("team", "\n", "median")
                )+
                annotate(
                        "text",
                        x = team_high$game_date,
                        y = team_high$postgame_elo + 100,
                        size = 3,
                        label = team_high$label
                )+
                annotate(
                        "text",
                        x = team_low$game_date,
                        y = team_low$postgame_elo - 100,
                        size = 3,
                        label = team_low$label
                )+
                facet_wrap(team ~.)+
                theme_minimal()+
                theme(plot.title = element_text(hjust = 0.5, size = 16),
                      plot.subtitle =  element_text(hjust = 0.5),
                      strip.text.x = element_text(size = 12))
        
}


plot_calibration = function(data) {
        
        data |>
                rename(
                        .pred_yes = home_prob
                ) |>
                cal_plot_breaks(
                        home_win,
                        .pred_yes,
                        event_level = 'second'
                )
}
