# Reset Environment -----
rm(list = ls())
load("run-files/snapshot_degradations-ready.Rdata")

# Start-up ----
# source(file = "r-scripts/testing_comparsion_algos.R") # load comparison algorithm functions
model_output = vector(mode = "list", length = nrow(deg)) # stores matches for each input

# Align Watchlist Names to [deg$prepd_name] Formatting  ----
# Mainly lazy copy of "_main.R" code; 
# TODO : Functionalize _main.R code and replace this section 
wl_data = raw

# Apply FML and Drop Middle Name Parameters
if(param.apply_fml | param.drop_middle_names){
  
  wl_data$prepd_name = raw$SDN_NAME
  
  # Apply FML and Drop Middle Name Parameters
  if(param.apply_fml | param.drop_middle_names){
    
    indiv_split = wl_data %>% 
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
  
}

wl_data$prepd_name[match(indiv_split$ENT_NUM, wl_data$ENT_NUM)] = indiv_split$name # replace edited names
rm(indiv_split)

wl_data = wl_data %>% # keep only the datat we need for comparison
  select(ENT_NUM, SDN_TYPE, prepd_name) 


# Generate Matches ----
message("Running Name Matching (Simulating WLF Model): ")
pb = progress::progress_bar$new(total = nrow(deg))
for(i in seq_along(deg$deg_index)){
  
  # iterate through each input name
  # ... generate matches
  model_output[[i]] = wl_data %>% 
    
    # only compare against names of a similar type
    filter(SDN_TYPE == deg$SDN_TYPE[i]) %>% 
    
    # initial threshold: distance length limit 
    mutate(model_dist = stringdist::stringdist(a = prepd_name, b = deg$test_name[i])) %>% 
    filter(model_dist < 40L) %>% # adjustable
    
    # secondary threshold: distance percentage limit
    mutate(model_score = 1 - (model_dist / nchar(prepd_name)),
           model_score = round(model_score, 4)) %>%
    filter(model_score > 0.75) # adjustable
  
  pb$tick()
}

# Wrap-up ----
names(model_output) = deg$deg_index
model_output = model_output %>% 
  bind_rows(., .id = "deg_index")

write_rds(x = model_output, file = "run-files/demo_wlf-screening-ouput.rds")

