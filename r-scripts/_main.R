# ABOUT --- 
# Main script file

# Start-up ----
rm(list = ls()); invisible(gc());
suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
require(magrittr, quietly = TRUE)
require(httr, quietly = TRUE)
require(assertthat, quietly = TRUE)

# Grab data ----
param.demo_mode = FALSE # demo run with degs and output analysis

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
param.apply_drop_tokens_entities = FALSE # see 'ref-files/drop-tokens_entities.txt'
param.apply_drop_tokens_individuals = TRUE # see 'ref-files/drop-tokens_individuals.txt'
param.apply_fml = TRUE # reorganize individual names to first-middle-last format

# param. TODO


# Run Helpers ----
# source("scripts/helper-funcs.R") TODO 

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


# Apply drop tokens: Entities
# TODO: currently results in superflous dropping 
# ... e.g. 'CASA DE CUBA' --> 'CA DE CUBA'
# ... via 'S.A.' entry
if(param.apply_drop_tokens_entities){
  ignore_tokens = readLines(con = "ref-files/drop-tokens_entities.txt", warn = FALSE) # read ref file
  
  if(length(ignore_tokens) > 0L){
    temp = raw$SDN_NAME
    for(i in seq_along(ignore_tokens)){
      # TODO: make this loop an *apply
      temp = str_remove(string = temp, pattern = fixed(ignore_tokens[i], ignore_case = TRUE))
    }
    
    ignore_tokens.select = which(raw$SDN_TYPE == "entity")
    raw$prepd_name = raw$SDN_NAME
    raw$prepd_name[ignore_tokens.select] = temp[ignore_tokens.select]
    rm(ignore_tokens, temp, ignore_tokens.select)
  }else{
    warning("'ref-files/drop-tokens_entities.txt' is empty; 'param.apply_drop_tokens_entities' ignored.")
  }
}

# Apply drop tokens: Individuals
if(param.apply_drop_tokens_individuals){
  ignore_tokens = readLines(con = "ref-files/drop-tokens_individuals.txt", warn = FALSE) # read ref file
  
  if(length(ignore_tokens) > 0L){
    temp = raw$SDN_NAME
    for(i in seq_along(ignore_tokens)){
      # TODO: make this loop an *apply
      temp = str_remove(string = temp, pattern = fixed(ignore_tokens[i], ignore_case = TRUE))
    }
    
    ignore_tokens.select = which(raw$SDN_TYPE == "individual")
    raw$prepd_name = raw$SDN_NAME
    raw$prepd_name[ignore_tokens.select] = temp[ignore_tokens.select]
    rm(ignore_tokens, temp, ignore_tokens.select)
  }else{
    warning("'ref-files/drop-tokens_entities.txt' is empty; 'param.apply_drop_tokens_individuals' ignored.")
  }
}

# Apply middle-name drop
# TODO ^
# ... apply to [prepd_name]

# Apply fml-formatting for individual names
# TODO ^
# ... apply to [prepd_name]

# Make Degradations----


