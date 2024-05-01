assess_predictions = function(data,
                              metrics = metric_set(roc_auc, brier_class, accuracy, precision, recall, f_meas, mcc, kap),
                              event_level = 'second') {
        
        data |>
                metrics(
                        truth = home_win,
                        estimate = home_pred,
                        home_prob
                )
}
