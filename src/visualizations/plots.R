plot_elo_historical_team <-
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
                        ggrepel::geom_text_repel(data =team_data,
                                                 aes(label = team_label),
                                                 max.overlaps = Inf,
                                                 fontface = "bold",
                                                 size = 4,
                                                 direction = "y",
                                                 hjust = -2,
                                                 segment.size = .7,
                                                 segment.alpha = .5,
                                                 segment.linetype = "dotted",
                                                 box.padding = .4,
                                                 segment.curvature = -0.1,
                                                 segment.ncp = 3,
                                                 segment.angle = 20
                        ) +
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
