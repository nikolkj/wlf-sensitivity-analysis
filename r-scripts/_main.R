# ABOUT --- 
# Main script file

# User Defined Parameters ----
param.demo_mode = TRUE # demo run with degs and output analysis
param.drop_middle_names = TRUE
# param. TODO


# Start-up ----
# source("scripts/helper-funcs.R") TODO 

# Grab and Prep data ----
# Pull copies of current OFAC data-files, parse and prep
source("r-scripts/pull-parse-enrich_sdn-files.R", echo = TRUE)
source("r-scripts/pull-parse-enrich_cons-files.R", echo = TRUE)

# Load prepared data
load(file = "run-files/sdn_files_parsed.RData")
load(file = "run-files/cons_files_parsed.RData")

# Make Degradations ---- 
# TODO 


