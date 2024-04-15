library(arrow)
#arrow::install_arrow()
library(tidymodels)
library(future)
set.seed(seed = 123, "L'Ecuyer-CMRG")  

nc = as.numeric(commandArgs(TRUE)[2])   
plan(multisession(workers = nc))
jan <- read_parquet('../data/fhvhv_tripdata_2024-01.parquet')
jan <- jan[1:40000,]

#tidymodels

taxi_split <- initial_split(jan,strata = driver_pay)
taxi_train <- training(taxi_split)
taxi_test <- testing(taxi_split)
taxi_folds <- vfold_cv(taxi_train, v = 5, strata = driver_pay)


taxi_recipe <- recipe(driver_pay ~ ., data = taxi_train) |> 
  step_rm(originating_base_num, on_scene_datetime, all_datetime_predictors(),PULocationID,DOLocationID) |> 
  step_dummy(all_nominal_predictors()) |> 
  step_corr(all_numeric_predictors(), threshold = 0.9) |>
  step_normalize(all_numeric_predictors()) |>
  step_zv(all_predictors()) 


glmnet_spec <- linear_reg(penalty = tune(),
                          mixture = tune()) |> 
  set_engine("glmnet") |> 
  set_mode('regression')

car_workflow <- workflow() |> 
  add_recipe(taxi_recipe) |> 
  add_model(glmnet_spec)

reg_metrics <- metric_set(rmse, mae, rsq)

car_results <- car_workflow |>
  tune_grid(resamples = taxi_folds,
            grid = 10,
            control = control_resamples(save_pred = T,parallel_over = 'everything'),
            metrics = reg_metrics)

best_lm <- car_results %>%
  select_best(metric = "rmse")

best_lm

final_wf <- 
  car_workflow %>% 
  finalize_workflow(best_lm)

final_fit = final_wf |> 
  last_fit(taxi_split) 

test_metrics = final_fit |> 
  collect_metrics() |> 
  pull(.estimate)

cat("Rmse:",test_metrics[1] , "\n", "Rsq:" , test_metrics[2], "\n")
