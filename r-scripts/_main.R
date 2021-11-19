# ABOUT --- 
# Main script file

# Start-up ----
rm(list = ls()); invisible(gc());
suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
require(magrittr, quietly = TRUE)
require(httr, quietly = TRUE)
require(assertthat, quietly = TRUE)

# Grab data ----
param.refesh_watchlists = TRUE # ignored if RData files not found

# Pull copies of current OFAC data-files, parse and prep
if(param.refesh_watchlists &
   length(dir(path = "run-files/", pattern = "(_parsed.RData)") > 1L)){
  # nada, don't refresh data sets;
  
}else{
  # pull fresh data
  source("r-scripts/pull-parse-enrich_sdn-files.R", echo = TRUE)
  source("r-scripts/pull-parse-enrich_cons-files.R", echo = TRUE)
}

# Load prepared data
load(file = "run-files/sdn_files_parsed.RData")
load(file = "run-files/cons_files_parsed.RData")

# User Defined Parameters ----
param.demo_mode = TRUE # demo run with degs and output analysis
param.ignore_alt_names = TRUE
param.apply_fml = TRUE # reorganize individual names to first-middle-last format
param.drop_middle_names = TRUE

# Run Helpers ----
source("r-scripts/helper-funcs.R")

# Prep data ----
# Make source data-frame for degradation creation
prim = bind_rows(sdn.prim, cons.prim) # merge 'prim' tbls
if(param.ignore_alt_names){
  # take only primary names
  raw = prim
  rm(prim)
}else{
  # take primary and alternative (aka) names
  # TODO: Align headers between 'prim' and 'alt' tbls
  raw = bind_rows(prim, sdn.alt, cons.alt)
}

rm(list = c(ls(pattern = "\\.prim"), ls(pattern = "\\.alt")))

raw$SDN_NAME = str_squish(raw$SDN_NAME)
raw$prepd_name = raw$SDN_NAME
raw = raw %>% # drop unused field
  select(-c(TITLE, CALL_SIGN, VESS_TYPE, TONNAGE, GRT, VESS_FLAG, VESS_OWNER, REMARKS)) 

# Apply FML and Drop Middle Name Parameters
if(param.apply_fml | param.drop_middle_names){
  
  indiv_split = raw %>% 
    filter(SDN_TYPE == "individual") %>% 
    select(ENT_NUM, prepd_name) %>%
    mutate(splits = str_count(string = prepd_name, pattern = ",")) %>% 
    filter(splits == 1) %>% 
    mutate(split_name = str_split(string = prepd_name, pattern = ","))
  
  indiv_split$split_l = sapply(indiv_split$split_name, function(x){x[1]})
  indiv_split$split_name.fm = sapply(indiv_split$split_name, function(x){
    str_split(trimws(x[2]), " ")
  })
  indiv_split$split_f = sapply(indiv_split$split_name.fm, function(x){x[1]})
  indiv_split$split_m = trimws(sapply(indiv_split$split_name.fm, function(x) {
    paste(x[-1], collapse = " ")
  }))
  
  if(param.drop_middle_names){
    # drop middle names 
    indiv_split$split_m = "" 
  }
  
  if(param.apply_fml){
    # First Middle (optional) Last format
    indiv_split$name = paste(indiv_split$split_f, indiv_split$split_m, indiv_split$split_l)
  }else{
    # Last, First Middle (optional) format
    indiv_split$name = paste0(indiv_split$split_l, ", ", paste(indiv_split$split_f, indiv_split$split_m))
  }
  
  indiv_split$name = str_squish(indiv_split$name)
  
}

raw$prepd_name[match(indiv_split$ENT_NUM, raw$ENT_NUM)] = indiv_split$name # replace edited names
rm(indiv_split)

# Apply program filters
# TODO ^

# Apply country filters
# TODO ^

# Apply middle-name drop
# TODO ^
# ... apply to [prepd_name]

# Apply fml-formatting for individual names
# TODO ^
# ... apply to [prepd_name]

# Make Degradations ----
deg = list()
source("r-scripts/degrade_basics.R", echo = TRUE)
source("r-scripts/degrade_entities.R", echo = TRUE)
# source("r-scripts/degrade_individuals.R") # TODO 
# source("r-scripts/degrade_aircraft.R") # TODO 
# source("r-scripts/degrade_vessels.R") # TODO 


deg = bind_rows(deg, .id = "scenario") 
if(any(trimws(deg$test_name) == "")){
  warning("Heads up, some of your scenario produced empty-string degradations. They're being dropped.")
  deg = deg %>% 
    filter(trimws(test_name) != "")
} 

deg = mutate(.data = deg,deg_index = row_number()) # index degradations

# Write to Degradations to Input-file -----
# ABOUT: Should be client application specific
if(param.demo_mode){
  write_rds(x = deg, file = "run-files/degradation_input_temp.rds")
}else{
  # TODO : Production Code
  # ... client-application specific, defined by dedicated user-defined parameter
}

  
# Prep Data for Performance Expectation Modeling ----
# # write to shiny-app 'data/' dir

# write_rds(x = deg, file = "run-files/degradation_rndm_smpl.rds")
# file.copy(from = "run-files/degradation_rndm_smpl.rds", "shiny_benchmark-expectations/data/degradation_rndm_smpl.rds")
# 
# # write to xlsx for manual adjudication
# deg = deg %>% 
#   select(ENT_NUM, deg_index, prepd_name, test_name) %>% 
#   mutate(sort_order = sample(c(1:nrow(deg)))) %>% 
#   arrange(desc(sort_order)) %>% 
#   select(-sort_order)
# 
# writexl::write_xlsx(deg, path = paste0("run-files/degradation_rndm_smpl_",as.numeric(Sys.time()), ".xlsx"))

# ---- EVERYTHING BELOW HERE SHOULD BE IN A SEPERATE SCRIPT -----
# ^ excludes demo-code 

# Model Performance Expectations ----
# TODO ^ 

# Model Output ----
# About: In production, there would be engine for parsing 
# ... model output (e.g. from actimize or prime) 
# .... matching inputs and outputs
# .... decisioning false-positive and true-positive matches
# .... and staging data for sensitivity analysis
#
if(param.demo_mode){
  source("r-scripts/demo_match-names.R")
  
}else{
  # TODO : Production Parsing Functions/Scripts 
}

# Model Sensitivity ----
if(param.demo_mode){
  
  
}else{
  # TODO : Production Analysis Functions/Scripts

}