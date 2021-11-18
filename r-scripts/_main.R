# ABOUT --- 
# Main script file

# Start-up ----
rm(list = ls()); invisible(gc());
suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
require(magrittr, quietly = TRUE)
require(httr, quietly = TRUE)
require(assertthat, quietly = TRUE)

# Grab data ----
param.demo_mode = TRUE # demo run with degs and output analysis

# Pull copies of current OFAC data-files, parse and prep
if(param.demo_mode &
   length(dir(path = "run-files/", pattern = "(_parsed.RData)") > 1L)){
  # nada, don't refresh data sets; running in demo mode
  
}else{
  # pull fresh data
  source("r-scripts/pull-parse-enrich_sdn-files.R", echo = TRUE)
  source("r-scripts/pull-parse-enrich_cons-files.R", echo = TRUE)
}

# Load prepared data
load(file = "run-files/sdn_files_parsed.RData")
load(file = "run-files/cons_files_parsed.RData")

# User Defined Parameters ----
param.ignore_alt_names = TRUE
param.apply_fml = TRUE # reorganize individual names to first-middle-last format
param.drop_middle_names = TRUE

# param. TODO


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

raw$SDN_NAME = trimws(raw$SDN_NAME)
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

raw$prepd_name = indiv_split$name[match(raw$ENT_NUM, indiv_split$name)] # replace edited names
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

# write to shiny-app 'data/' dir
deg = deg %>% bind_rows() %>% mutate(deg_index = row_number())
write_rds(x = deg, file = "run-files/degradation_rndm_smpl.rds")
file.copy(from = "run-files/degradation_rndm_smpl.rds", "shiny_benchmark-expectations/data/degradation_rndm_smpl.rds")

# write to xlsx for manual adjudication
deg = deg %>% 
  select(ENT_NUM, deg_index, prepd_name, test_name) %>% 
  mutate(sort_order = sample(c(1:nrow(deg)))) %>% 
  arrange(desc(sort_order)) %>% 
  select(-sort_order)

writexl::write_xlsx(deg, path = paste0("run-files/degradation_rndm_smpl_",as.numeric(Sys.time()), ".xlsx"))
# Model Performance Expectations ----



# Model Sensitivity ----
