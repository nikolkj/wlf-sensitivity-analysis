# ABOUT --- 
# Main script file

# Start-up ----
rm(list = ls()); invisible(gc());

# Load Libraries
suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
require(magrittr, quietly = TRUE)
require(httr, quietly = TRUE)
require(assertthat, quietly = TRUE)

# Run in Demo-mode?
# ... Watchlist data will not be refreshed if RData files found;
# ... Simple matching algorithm will be used to simulate watchlist screening model
# .... output;
# ... TODO: placeholder for any other impacts                                                    
param.demo_mode = TRUE # demo run with degs and output analysis

# Grab data ----
param.refresh_watchlists = TRUE # FALSE is ignored if RData files not found;

# Pull copies of current OFAC data-files, parse and prep
# ... [param.refresh_watchlists] is IGNORED if demo-mode is enabled
# ... unless the "run-files/" dir does not have any watchlist files.

check_for_wldata = length(dir(path = "run-files/", pattern = "(_parsed.RData)")) > 1L # are there files?
if(param.demo_mode){param.refresh_watchlists = FALSE} # overwrite if demo-mode.

if(!check_for_wldata | param.refresh_watchlists){
  
  # pull fresh data
  # ... add additional pull-scripts as necessary
  source("r-scripts/pull-parse-enrich_sdn-files.R", echo = TRUE)
  source("r-scripts/pull-parse-enrich_cons-files.R", echo = TRUE)
  
}

rm(check_for_wldata)

# Load prepared data
load(file = "run-files/sdn_files_parsed.RData")
load(file = "run-files/cons_files_parsed.RData")

# User Defined Parameters ----
# Degradation Creation Parameters
param.ignore_alt_names = TRUE # ignore OFAC AKAs?
param.apply_fml = TRUE # reorganize individual names to first-middle-last format
param.drop_middle_names = TRUE # drop middle names from degradations?

# Sensitivity Analysis Parameters
param.perf_thld_high = .9 # true-positive rate lower bound for "sufficient" performance for given scenario
param.perf_thld_low = .3 # true-positive rate upper-bound for "deficient" performance for given scenario

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
  
  stop(paste0("{param.ignore_alt_names = FALSE} currently not supported;",
              "\n",
              "TODO: Align headers between 'prim' and 'alt' tbls.")
       )
  
  # raw = bind_rows(prim, sdn.alt, cons.alt) # place-holder, pending header alignment.
}

rm(list = c(   # clean-up.
  ls(pattern = "\\.prim"), # primary name sets
  ls(pattern = "\\.alt") # alt name setsts
))

# Drop unused field
raw = raw %>% 
  select(-c(TITLE, CALL_SIGN, VESS_TYPE, TONNAGE, GRT, VESS_FLAG, VESS_OWNER, REMARKS)) 

# ~~~~ Apply name pre-processing ~~~~
# ... remove extraneous white-space;
# ... apply any relevant user-defined parameters 
raw$SDN_NAME = str_squish(raw$SDN_NAME) 
raw$prepd_name = raw$SDN_NAME

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

# ~~~~ Other Pre-processing ~~~~
# ... Apply any data-set filters;
# ... etc; 

# Apply program filters
# TODO ^

# Apply country filters
# TODO ^

rm(list = c(
  ls(pattern = "\\.add"), # address data sets
  ls(pattern = "program_catalog") # program catalog data sets
))

  
# Make Degradations ----
# Make a snapshot to isolate from any vars
# ... created in the "Make Degradation" code-block scripts
deg = list() # re-allocate empty list for degradation output
save.image(file = "run-files/snapshot_prepared-data.Rdata")

# Run degradation scripts 
source("r-scripts/degrade_basics.R", echo = TRUE)
source("r-scripts/degrade_entities.R", echo = TRUE)
# source("r-scripts/degrade_individuals.R") # TODO 
# source("r-scripts/degrade_aircraft.R") # TODO 
# source("r-scripts/degrade_vessels.R") # TODO 

# Reset environment
rm(list = ls())
load("run-files/snapshot_prepared-data.Rdata")

# Read degradation script output
deg_basics = read_rds("run-files/degradation-output_basics.rds")
deg_entities = read_rds("run-files/degradation-output_entities.rds")
# deg_individuals = read_rds(...) # TODO 
# deg_aircraft = read_rds(...) # TODO 
# deg_vessels = read_rds(...) # TODO 

# Combine Output
deg = bind_rows(c(deg_basics, 
                  deg_entities
                  # TODO: add individual/vessel/aircraft dfs once available;
                  ),
                .id = "scenario") 

rm(list = ls(pattern = "^deg_")) # clean-up

# Output Checks ...
if(any(trimws(deg$test_name) == "")){
  warning("Heads up, some of your scenario produced empty-string degradations. They're being dropped.")
  deg = deg %>% 
    filter(trimws(test_name) != "")
} 

# Index Output Degradations 
deg = mutate(.data = deg,deg_index = row_number()) 

# Write Degradations to Input-file -----
# ABOUT: Writes model specific output-file, as defined by user selection, for ingestion into 
# ... client system (e.g. Prime, Actimize); Corresponding logic pending development (TODO)
# .... Demo-mode writes RDS of "deg" var to "run-files/".

if(param.demo_mode){
  
  # Demo-mode: write to temporary data file
  write_rds(x = deg, file = "run-files/demo_degradations-ready.rds")
  
}else{
  
  # TODO: Production Code
  # ... client-application specific, defined by dedicated user-defined parameters / selections
  
}

# Make a snapshot to isolate from any vars
# ... WLF simulation / WLF Output Parsing Scripts
save.image(file = "run-files/snapshot_degradations-ready.Rdata")

# Simulate WLF Model Screening ----
# ONLY DEMO MODE
if(param.demo_mode){
  
  source("r-scripts/demo_match-names.R")
  
}else{
  # do nothing. 
}

# Input/Output Data Integration ----
# Integration of output produced in section "Write Degradations to Input-file"
# ... and ingested model output; as defined by user-selection;
# .... matching MUST allow direct matching between specific input [deg_index] values
# .... and individual model match results.

if(param.demo_mode){
 
  # Reset environment
  rm(list = ls())
  load(file = "run-files/snapshot_degradations-ready.Rdata")
  
  # Read simulated output
  wlf_ouput = read_rds(file = "run-files/demo_wlf-screening-ouput.rds")
  
}else{
  # TODO
  # ... Separate scripts should be maintained to parse output 
  # .... based on client system;
  # ... Output should be written to data-frame and saved to RDS file;
  
  # Reset environment
  rm(list = ls())
  load("run-files/snapshot_prepared-data.Rdata")
  
  # read parsed output
  # wlf_ouput = read_rds(...) # placeholder

}

# ~~~ Integrate screening output to degradation data ~~~
# Evaluate whether each match was a true-positve match
# ... or a false-positive match;
# Assumes that wlf_ouput$deg_index maps back to the 
# ... [deg] data-frame, and that true/false-positive 
# ... can be determined by comparing [ENT_NUM], 
# ... unique watchlist-id values;
# TODO: Allow user defined evaluation of true/false-positive
# ... outcomes; either by name, id, or other method (as applicable);

wlf_ouput = wlf_ouput  %>%
  mutate(ENT_NUM = as.numeric(ENT_NUM),
         deg_index = as.integer(deg_index)
         ) %>%
  # Integrate data-sets for comparison
  left_join(
    x = .,
    y = deg %>% 
      select(deg_index, ENT_NUM) %>%
      rename(ent_num = ENT_NUM) %>% 
      mutate(ent_num = as.numeric(ent_num),
             deg_index = as.integer(deg_index)
             ),
    by = "deg_index"
  ) %>%
 # Determine whether match corresponds to true/false-positive
 mutate(model_result = ifelse(ENT_NUM == ent_num,
                              TRUE, # true-positive
                              FALSE # false-positive
                              )
        )

# Write results to [deg] for modeling
deg$true_positive_match = NA # pre-allocate
deg$false_positive_matches = 0 # pre-allocate
for(i in seq_along(deg$true_positive_match)){
  
  # filter [ENT_NUM] vals for comparison
  matches = wlf_ouput$ENT_NUM[which(wlf_ouput$deg_index == deg$deg_index[i])] 
  assertthat::noNA(matches)
  
  # evaluate matches
  deg$true_positive_match[i] = length(intersect(deg$ENT_NUM[i], matches)) > 0L 
  if(length(matches) > 0L){
    deg$false_positive_matches[i] = length(matches) - 1L # ignore true-positive match
  }
  
}

rm(wlf_ouput, matches) # clean-up

# Make a snapshot to isolate from any vars
# ... sensitivity analysis scripts
save.image(file = "run-files/snapshot_integrated-datasets.Rdata")

# Model Sensitivity ----
# Summarizes and models WLF algorithm sensitivities
if(param.demo_mode){
  
  
}else{
  # TODO : Production Analysis Functions/Scripts

}