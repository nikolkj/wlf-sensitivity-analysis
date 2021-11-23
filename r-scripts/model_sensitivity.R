# Reset Environment ----
rm(list = ls()); 
load(file = "run-files/snapshot_integrated-datasets.Rdata")

# Summarize Model Performance ----
# Performance Summary: What percentage of samples resulted in a true-positive match?
perf_summary = deg %>% 
  group_by(scenario, true_positive_match) %>% 
  count() %>%
  ungroup() %>% 
  group_by(scenario) %>% 
  mutate(p = n/sum(n)) %>% 
  filter(true_positive_match) %>% 
  arrange(desc(p)) %>% 
  mutate(testing_outcome = case_when(p >= param.perf_thld_high ~ "Sufficient", 
                                     p <= param.perf_thld_low ~ "Deficient", 
                                     TRUE ~ "To be Determined")
  )
  
# Visualizations of Scenario Performance ----
# ... PCA Projection of model output
# Visualizations basd on PCA PC1 & PC2 projections of distance benchmark calculations
# ... facet by scenario, coloring by test-outcome
deg_pca = deg %>% 
  group_by(scenario) %>% 
  nest()

deg_pca$pca = lapply(deg_pca$data, function(df){
 
  df = df %>% 
    select(starts_with("dist_"))
  
  df.nzv = caret::nearZeroVar(df)
  df = df %>% 
    select(-all_of(df.nzv)) %>% 
    scale(x = ., center = TRUE, scale = TRUE) %>% 
    as_tibble() 
  
  df = tryCatch(expr = {prcomp(df)}, error = function(e){return(NULL)})
  
  if(!is.null(df)){
    df = as_tibble(df$x) 
  }
  
  return(df)

})

deg_pca %>% 
  unnest(c(data, pca)) %>% 
  select(scenario, true_positive_match, PC1, PC2) %>% 
  mutate(true_positive_match = factor(true_positive_match, levels = c(FALSE, TRUE)), 
         scenario = factor(scenario)) %>% 
  ggplot(., aes(PC1, PC2, color = true_positive_match)) +
  geom_point(alpha = 0.5) +
  facet_wrap(facets = . ~ scenario, scales = "free") 

deg_pca %>% 
  unnest(c(data, pca)) %>% 
  select(scenario, true_positive_match, PC2, PC3) %>% 
  mutate(true_positive_match = factor(true_positive_match, levels = c(FALSE, TRUE)), 
         scenario = factor(scenario)) %>% 
  ggplot(., aes(PC2, PC3, color = true_positive_match)) +
  geom_point(alpha = 0.5) +
  facet_wrap(facets = . ~ scenario, scales = "free") 

# Analysis: Sufficient Performance Scenarios ----
# Q1: Are false-positive / no-result outcomes outliers from the 
# ... true-positive population. 
# .... Analysis options can be simple analysis of PC1 IQR distances
# .... or a more complicated multidimensional outlier analysis (e.g. isolation forest)
# .
# No further questions. 

# do nothing.

# Analysis: Deficient Performance Scenarios ----
# No questions; subjective question to management of whether they expect the 
# ... model to generate matches under such scenarios, if appropriate (e.g. business designation replacement).
# .
# No further questions.

# do nothing.

# Analysis: To-be-Determined Performance Scenarios ----
# Q1: Is there a statistically significant difference between false-positive / no-result outcome population 
# ... and the true-positive population?
# .... Analysis options can be a simple t-test of PC1 projects (assuming explain variance is high) 
# .... to determine whether the population means are different.
# .
# Q2-a: If Q1 is TRUE, does the decision boundary produced by the model align with management expectations.
# ... i.e. if management evaluates near-boundary samples, will their classifications align, or push the boundary
# .... to a more conservative position?
# .
# Q2-b: IF Q1 is FALSE, no additional questions; subjective question to management of whether they expect the 
# ... model to generate matches under such scenarios, if appropriate (e.g. business designation replacement),
# ... because model behaviour appears to be random and not generating consistent results.
# .
# No further questions.

require(tidymodels)

# set func-name clash preference to tidymodels
# x scales::discard()      masks purrr::discard()
# x magrittr::extract()    masks tidyr::extract()
# x dplyr::filter()        masks stats::filter()
# x recipes::fixed()       masks stringr::fixed()
# x assertthat::has_name() masks tibble::has_name()
# x dplyr::lag()           masks stats::lag()
# x magrittr::set_names()  masks purrr::set_names()
# x yardstick::spec()      masks readr::spec()
tidymodels_prefer() 
# TODO preferences should be dropped after modeling is complete.

# filter and select data for modeling
deg_model = deg %>% 
  filter(scenario %in% perf_summary$scenario[which(perf_summary$testing_outcome == "To be Determined")]) %>% 
  select(scenario, deg_index, prepd_name, test_name, 
         # place holder for any non-"dist_*" metrics that 
         # ... should be included in modeling processes
         starts_with("dist_"),
         true_positive_match
         ) %>% 
  group_by(scenario) %>% 
  nest()

# model each scenario
deg_model$train_data = vector(mode = "list", length = nrow(deg_model))
deg_model$test_data = vector(mode = "list", length = nrow(deg_model))
deg_model$fit = vector(mode = "list", length = nrow(deg_model))
deg_model$predict = vector(mode = "list", length = nrow(deg_model))
deg_model$roc_curv = vector(mode = "list", length = nrow(deg_model))
deg_model$roc_auc = vector(mode = "list", length = nrow(deg_model))
deg_model$contingency = vector(mode = "list", length = nrow(deg_model))
deg_model$accuracy = vector(mode = "list", length = nrow(deg_model))
deg_model$mcc = vector(mode = "list", length = nrow(deg_model))

for(i in seq_along(deg_model$scenario)){
  message(paste0("Modeling Scenario: ", deg_model$scenario[i]))
  
  dat = deg_model$data[[i]]
  dat$true_positive_match = factor(dat$true_positive_match, ordered = FALSE)
  
  # Create splits
  dat_split = rsample::initial_split(data = dat, prop = 0.60, strata = true_positive_match)
  dat_train = rsample::training(dat_split)
  dat_test = rsample::testing(dat_split)
  
  deg_model$train_data[[i]] = dat_train # archive
  deg_model$test_data[[i]] = dat_test # archive
  
  # Create Recipe
  dat_rec = dat_train %>% 
    recipes::recipe(data = dat_train, formula = true_positive_match ~ .) %>% 
    recipes::update_role(recipe = ., deg_index, new_role = "id") %>% 
    recipes::update_role(recipe = ., prepd_name, test_name, new_role = "input-detail") %>% 
    
    # drop zero-variance predictors
    recipes::step_zv(recipes::all_numeric_predictors()) %>%
    
    # data-normalization
    recipes::step_center(recipes::all_numeric_predictors()) %>%
    recipes::step_scale(recipes::all_numeric_predictors()) %>% 
    recipes::step_pca(all_numeric_predictors(), keep_original_cols = FALSE, threshold = 0.95)
  
  
  # Set Modeling Engine
  dat_mdl_lda = discrim::discrim_linear() %>%
    set_engine('MASS')
  
  # Create Workflow
  dat_wlf = workflows::workflow() %>% 
    add_recipe(dat_rec) %>% 
    add_model(dat_mdl_lda)
  
  # Fit Model
  # ... just doing LDA for now
  dat_wlf.fit = parsnip::fit(object = dat_wlf, data = dat_train)
  dat_wlf.predict = predict(object = dat_wlf.fit, new_data = dat_test, type = "prob")
  
  deg_model$fit[[i]] = dat_wlf.fit # archive
  
  # Evaluate Model Performance
  dat_wlf.predict = dat_wlf.predict %>% 
    mutate(truth = dat_test$true_positive_match,
           predicted = .pred_TRUE > .pred_FALSE,
           predicted = factor(predicted),
           deg_index = dat_test$deg_index,
           prepd_name = dat_test$prepd_name,
           test_name = dat_test$test_name
           ) %>% 
    select(deg_index, prepd_name, test_name, everything())
  
  deg_model$predict[[i]] = dat_wlf.predict # archive
  
  deg_model$contingency[[i]]= dat_wlf.predict %>% # archive
    select(truth, predicted) %>% 
    table()
  
  deg_model$accuracy[[i]] = yardstick::accuracy(data = dat_wlf.predict, truth, predicted) # archive
  deg_model$mcc[[i]] = yardstick::mcc(data = dat_wlf.predict, truth, predicted) # archive
  
  deg_model$roc_curv[[i]] = yardstick::roc_curve(dat_wlf.predict, truth, .pred_FALSE) %>% # archive
    autoplot()
  
  deg_model$roc_auc[[i]] = yardstick::roc_auc(dat_wlf.predict, truth, .pred_FALSE) # archive
  
}

# Modeling Client Expectations ----
# Mcnemar Test between test-set and client feedback

# Generate sample for review
deg_expect = deg_model %>% 
  select(scenario, data) %>% 
  unnest(cols = c(data)) %>% 
  select(scenario, deg_index, prepd_name, test_name, true_positive_match) %>%
  group_by(scenario, true_positive_match) %>% 
  sample_n(40) %>% 
  arrange(deg_index) %>%
  ungroup() %>%
  mutate(client_expectation = NA)

# drop model-output [true_positive_match] if not in demo-mode
if(!param.demo_mode){
  deg_expect = deg_expect %>% 
    select(-true_positive_match)
}

# Write to File
# ... to be given to client for evaluation
split(deg_expect, deg_expect$scenario) %>% # create list of data-frames
  writexl::write_xlsx(x = ., path = "run-files/scenario_expectations.xlsx")

rm(deg_expect)

if(param.demo_mode){
  # copy to response directory if demo-mode
  file.copy(from = "run-files/scenario_expectations.xlsx", 
            to = "response-files/scenario_expectations-response-demo.xlsx")
}

# Read Client Response
response_file = dir(path = "response-files/", pattern = "expectation", full.names = TRUE)
response_file.info = file.info(response_file) %>% 
  as_tibble() %>% 
  mutate(path = response_file)

# ... grab latest file
response_file = response_file.info %>% 
  slice(which.max(mtime)) %>% 
  slice(1) %$%
  path

# ... read data
response_file.sheets = readxl::excel_sheets(path = response_file)
response_data = lapply(response_file.sheets, function(x){
  readxl::read_excel(path = response_file, sheet = x)
})

response_data = response_data %>% 
  bind_rows() %>% 
  group_by(scenario) %>% 
  nest()
  
# Simulate client response, Demo-mode ONLY
if(param.demo_mode){
  
  # Simulate Client Feedback
  # ... fit using established scenario model with 
  # .... cutoff threshold > 0.50
  for(i in seq_along(response_data$scenario)){
    
    # pull in historic metrics
    response_data$data[[i]] = response_data$data[[i]] %>% 
      left_join(x = .,
                y = deg_model %>% 
                  filter(scenario == response_data$scenario[i]) %>% 
                  .$data %>% .[[1]] %>%
                  select(deg_index, starts_with("dist_")),
                by = "deg_index"
                  )
    # get model
    mdl = deg_model$fit[[which(deg_model$scenario == response_data$scenario[i])]]
    
    # fit model
    response_data$data[[i]]$client_expectation = predict(object = mdl,
                                                                new_data = response_data$data[[i]], 
                                                                type = "prob"
                                                                ) %>%
      mutate(prediction = .pred_TRUE > 0.80,
             prediction = factor(prediction)) %$% 
      prediction
    
    # remove historic metrics
    response_data$data[[i]] = response_data$data[[i]] %>% 
      select(-starts_with("dist_"))
                                                            
  }
  
}

# Evaluate alignment between model performance and client expectations
response_data$mcnemar = vector(mode = "list", length = nrow(response_data))
response_data$conf_mat = vector(mode = "list", length = nrow(response_data))

response_data$mcnemar = lapply(response_data$data, function(x) {
  mcnemar.test(x = x$true_positive_match,
               y = x$client_expectation)
})

response_data$conf_mat = lapply(response_data$data, function(x) {
  table(
    model_class = x$true_positive_match,
    expected_class = x$client_expectation
  )
})

response_data$p_value = sapply(response_data$mcnemar, function(x){x$p.value})
perf_summary$testing_outcome_final = perf_summary$testing_outcome
perf_summary = perf_summary %>% 
  left_join(x = ., y = response_data %>% select(scenario, p_value),
            by = "scenario") %>% 
  # determine final disposition based on McNemar p.value results
  mutate(testing_outcome_final = case_when(is.na(p_value) ~ testing_outcome_final,
                                           p_value > 0.05  ~ "Sufficient",
                                           TRUE ~ "Deficient")
  ) %>% 
  select(-p_value)

perf_summary # print to console
# TODO script output ...
  

# Modeling Exposure ----
# Only applicable for scenarios where model performance is 
# ... not aligned with management expectations;
# Estimate the number of similar names to those resulting in 
# ... no true-positive matches for affected scenarios;