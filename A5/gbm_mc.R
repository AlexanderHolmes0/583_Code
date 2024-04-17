suppressMessages(library(gbm))
suppressMessages(library(arrow))
suppressMessages(library(tidymodels))

set.seed(seed = 123, "L'Ecuyer-CMRG")
jan <- read_parquet('fhvhv_tripdata_2024-01.parquet')
jan <- jan[1:400000,]

n = nrow(jan)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = jan[-i_test, ]
test = jan[i_test, ]

taxi_recipe <- recipe(base_passenger_fare ~ ., data = train) |> 
  step_rm(originating_base_num,all_datetime_predictors(),PULocationID,DOLocationID) |> 
  step_dummy(all_nominal_predictors()) |> 
  step_normalize(all_numeric_predictors()) |>
  step_corr(all_numeric_predictors(), threshold = 0.9) |>
  step_zv(all_predictors())

train_prep <- juice(prep(taxi_recipe))
test_prep <- bake(prep(taxi_recipe), new_data = test)

nc = as.numeric(commandArgs(TRUE)[2])

gbm.all = gbm(base_passenger_fare ~ ., data=train_prep, n.trees= 500, cv.folds = 5, n.cores=nc, distribution = "gaussian")

pred = predict(gbm.all, test_prep)

rmse = sqrt(mean((pred - test_prep$base_passenger_fare)^2))
cat(nc," core rmse: ", rmse, "\n")

