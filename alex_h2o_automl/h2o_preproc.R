#Welcome to h2o in R
suppressMessages(library(arrow))
suppressMessages(library(tidymodels))
suppressMessages(library(h2o))

jan <- read_parquet("/projects/bckj/Team5/data/fhvhv_tripdata_2024-01.parquet")

# Split the data
n = nrow(jan)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = jan[-i_test, ]
test = jan[i_test, ]

# Define the recipe
taxi_recipe <- recipe(base_passenger_fare ~ ., data = train) |> 
  step_rm(originating_base_num,all_datetime_predictors(),PULocationID,DOLocationID) |> 
  step_dummy(all_nominal_predictors()) |> 
  step_normalize(all_numeric_predictors()) |>
  step_corr(all_numeric_predictors(), threshold = 0.9) |>
  step_zv(all_predictors())

# Prep the recipe
train_prep <- juice(prep(taxi_recipe))
test_prep <- bake(prep(taxi_recipe), new_data = test)


# start the h2o cluster
# get some THICK RAM up in here
h2o.init(min_mem_size = "180g")

# Convert to h2o frame
train_data <- as.h2o(train_prep)
test_data <- as.h2o(test_prep)

rm(train_prep, test_prep, train, test)


print(paste("Training data has nrows ",
            nrow(train_data),
            " and ncols ",
            ncol(train_data)))
print(paste("Testing data has nrows ",
            nrow(test_data),
            " and ncols ",
            ncol(test_data)))

# Identify predictors and response
y <- "base_passenger_fare"
x <- setdiff(names(test_data), y)

# run some automl up in here
auto_ml_res <- h2o.automl(y = y, 
                          x = x,
			  max_models = 20,
                          training_frame = train_data,
                          verbosity = "info",
                          nfolds = 10,
                          max_runtime_secs=3060,
                          seed = 42)

#model_leaderboard <- h2o.get_leaderboard(auto_ml_res)

print("AutoML Model Leader Board:")
# View the AutoML Leaderboard
lb <- auto_ml_res@leaderboard
print(lb, n = nrow(lb))

# best model based on cross-validation metrics
best_model <- h2o.get_best_model(auto_ml_res)
print(best_model)

# Save the model
model_path <- h2o.saveModel(object = best_model, path = getwd(), force = TRUE)
print(model_path)
print('Best model saved')

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
