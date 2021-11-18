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
param.drop_middle_names = TRUE
param.apply_fml = TRUE # reorganize individual names to first-middle-last format

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

# Make Degradations----


