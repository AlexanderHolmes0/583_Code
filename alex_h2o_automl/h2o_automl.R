library(h2o)
library(dplyr)

# start the h2o cluster
h2o.init(min_mem_size = "160g")

# load in our data
taxi_data <- h2o.importFile("/projects/bckj/Team5/data/fhvhv_tripdata_2024-01.parquet"

# split data where training has 80% data
split_data <- h2o.splitFrame(taxi_data, ratios = 0.80)
train_data <- split_data[[1]]
test_data <- split_data[[2]]
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
                          nfolds = 3,
                          max_runtime_secs=30)

# get the leader board of models
model_leaderboard <- h2o.get_leaderboard(auto_ml_res)
print("AutoML Model Leader Board:")
print(model_leaderboard)

# best model based on cross-validation metrics
best_model <- h2o.get_best_model(auto_ml_res)
# overall model details
print(best_model)

# get model info we care about
model_info <- list(best_model_features = best_model@parameters$x,
                   best_model_target = best_model@parameters$y,
                   total_training_time_secs = auto_ml_res@training_info$duration_secs)
print("Best Model Features Used:")
print(model_info$best_model_features)
print("Best Model Target Variable:")
print(model_info$best_model_target)
print("Total Training time elapsed:")
print(model_info$total_training_time_secs)

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
