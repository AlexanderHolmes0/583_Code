suppressMessages(library(arrow,quietly = TRUE))
suppressMessages(library(tidymodels,verbose = FALSE,warn.conflicts = FALSE,quietly = TRUE))
library(future)
plan(multisession, workers = as.numeric(commandArgs(TRUE)[2]))

#nc = as.numeric(commandArgs(TRUE)[2])   
jan <- read_parquet('fhvhv_tripdata_2024-01.parquet')
jan <- jan[1:400000,]

#tidymodels

taxi_split <- initial_split(jan,strata = base_passenger_fare)
taxi_train <- training(taxi_split)
taxi_test <- testing(taxi_split)
taxi_folds <- vfold_cv(taxi_train, v = 5, strata = base_passenger_fare)


taxi_recipe <- recipe(base_passenger_fare ~ ., data = taxi_train) |> 
  step_rm(originating_base_num, on_scene_datetime, all_datetime_predictors(),PULocationID,DOLocationID) |> 
  step_dummy(all_nominal_predictors()) |> 
  step_corr(all_numeric_predictors(), threshold = 0.9) |>
  step_normalize(all_numeric_predictors()) |>
  step_zv(all_predictors()) 


lm_spec <- linear_reg() |> 
  set_engine("lm") |> 
  set_mode('regression')

car_workflow <- workflow() |> 
  add_recipe(taxi_recipe) |> 
  add_model(lm_spec)

reg_metrics <- metric_set(rmse, mae, rsq)

car_results <- car_workflow |>
  fit_resamples(resamples = taxi_folds,
            control = control_resamples(parallel_over = 'resamples'),
            metrics = reg_metrics)

best_lm <- car_results %>%
  select_best(metric = "rmse")

final_wf <- 
  car_workflow %>% 
  finalize_workflow(best_lm)

final_fit = final_wf |> 
  last_fit(taxi_split) 

test_metrics = final_fit |> 
  collect_metrics() |> 
  pull(.estimate)

cat("Rmse:",test_metrics[1] , "\n", "Rsq:" , test_metrics[2], "\n")

plan(sequential)

