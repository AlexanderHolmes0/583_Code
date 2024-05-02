library(h2o)
library(dplyr)

# start the h2o cluster
# get some THICK RAM up in here
h2o.init(min_mem_size = "180g")

taxi_data <- h2o.importFile("/projects/bckj/Team5/data/fhvhv_tripdata_2024-01.parquet")

# split data where training has 80 percent data
split_data <- h2o.splitFrame(taxi_data, ratios = 0.80)
train_data <- split_data[[1]]
test_data <- split_data[[2]]
# save memory by deleting full taxi data
#h2o.rm(taxi_data)

print(paste("Training data has nrows ",
            nrow(train_data),
            " and ncols ",
            ncol(train_data)))
print(paste("Testing data has nrows ",
            nrow(test_data),
            " and ncols ",
            ncol(test_data)))

# run some automl up in here
auto_ml_res <- h2o.automl(y = "base_passenger_fare",
                          training_frame = train_data,
                          verbosity = "info",
                          nfolds = 10,
                          max_runtime_secs=3060)

model_leaderboard <- h2o.get_leaderboard(auto_ml_res)
print("AutoML Model Leader Board:")
print(model_leaderboard)

# best model based on cross-validation metrics
best_model <- h2o.get_best_model(auto_ml_res)
print(best_model)

print("Best Model Features Used:")
print(best_model@parameters$x)
print("Best Model Target Variable:")
print(best_model@parameters$y)
print("Total Training time (sec) elapsed:")
print(auto_ml_res@training_info$duration_secs)

var_imp_plot <- h2o.varimp_plot(best_model)
if (is.null(var_imp_plot)) {
  print("The best model didn't have variable importance values.")
} else {
  dev.print(var_imp_plot, "best_model_variable_importance.png")
}
dev.print(h2o.learning_curve_plot(best_model), "best_model_learning_curve.png")
dev.print(h2o.residual_analysis_plot(best_model, test), "best_model_residual_plot.png")


# shutdown the h2o cluster
h2o.shutdown(prompt = FALSE)
