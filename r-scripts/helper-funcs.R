# Split First & Last Name for person-entries
split_names = function(dat){
  
  dat.persons = dat %>% 
    filter(SDN_TYPE == "individual") %>% 
    mutate(name_split = str_split_fixed(string = SDN_NAME, pattern = ",", n = 2),
           first_name = name_split[,2] %>% trimws() %>% toupper(),
           last_name = name_split[,1] %>% trimws() %>% toupper()
    ) %>% 
    select(-name_split)
  
  dat = dat %>% 
    # filter to non-persons and preallocate fields
    filter(SDN_TYPE != "individual") %>% 
    mutate(first_name = NA, 
           last_name = NA) %>% 
    # bind data-frames
    bind_rows(., dat.persons) %>% 
    arrange(desc(ENT_NUM))
  
  
  return(dat)
  
}

# Make Pretty Names
prettyName = function(first_name = NA, co_or_last_name){
  if(anyNA(co_or_last_name) | 
     any(is.null(co_or_last_name)) | 
     length(first_name) != length(co_or_last_name)
  ){
    stop("[co_or_last_name] cannot have any missing or null values")
  }
  
  ifelse(!is.na(first_name), 
         paste(first_name, co_or_last_name),
         co_or_last_name) %>% 
    stringr::str_to_title() %>% 
    stringr::str_squish() %>% 
    return(.)
}

# Gramify
gramify = function(string_vec, ngrams = 3L, rolling = TRUE){
  assertthat::assert_that(rolling, msg = "simple Ngram not supported.")
  assertthat::is.string(string_vec)
  assertthat::is.count(ngrams)
  assertthat::assert_that(ngrams > 1, msg = "ngrams must be greater than 1.")
  if(ngrams > 3L){
    warning("recommend using ngram value between [2,3].")
  }
  
  if(rolling){
    # rolling n-grams
    grams = lapply(string_vec, function(x) {
      sapply(1:(nchar(x) - ngrams + 1), function(z) {
        substr(x, z, z + ngrams - 1)
      })
    })
    
  }else{
    # simple n-grams
    # TODO
  }
  
  return(grams)
  
}

# Calculate Distances ----
# ABOUT: Calculates string distance metrics between two string vectors

# prepd_name = dat$prepd_name[100] # testing, do not run
# test_name = dat$test_name[100] # testing, do not run
degDistance = function(prepd_name, test_name){
  # Levenshtein Distance Metrics
  dist_lev = stringdist::stringdist(a = prepd_name, b = test_name)
  dist_lev_pcnt = round(dist_lev / nchar(prepd_name), 4)
  
  # Ngram Distance Metrics
  prepd_name.grams = gramify(string_vec = prepd_name)
  test_name.grams = gramify(string_vec = test_name)
  
  dist_ngram = vector(mode = "integer", length = length(prepd_name))
  for(i in seq_along(dist_ngram)){
    dist_ngram[i] = length(setdiff(test_name.grams[[i]], prepd_name.grams[[i]]))
  }
  
  dist_ngram_pcnt = round((dist_ngram/sapply(prepd_name.grams, length)), 4)
  
  # Phonetic Distance Metrics
  # Apply phonetic approximations then compute distance between 
  # ... phonetic representations.
  # .... Assumes ACSII character-set only; if the non-OFAC lists are integrated
  # .... additional normalization procedures should be applied 
  # .... for UTF8-to-ASCII character transliteration before metaphone encodings
  # .... are applied. 
  prepd_name.phon = str_split(string = prepd_name, pattern = "\\s+") %>%
    lapply(., str_remove_all, pattern = "[^[A-z]]") %>% 
    lapply(., phonics::metaphone) %>% 
    sapply(., paste, collapse = " ")
  
  test_name.phon = str_split(string = test_name, pattern = "\\s+") %>%
    lapply(., str_remove_all, pattern = "[^[A-z]]") %>% 
    lapply(., phonics::metaphone) %>% 
    sapply(., paste, collapse = " ")
  
  dist_phon = stringdist::stringdist(a = prepd_name.phon, b = test_name.phon)
  dist_phon_pcnt = round(dist_phon / nchar(prepd_name.phon), 4)
  
  # TODO: Other Distance Metrics
  
  # Create Output Tibble
  output = tibble(dist_lev, dist_lev_pcnt,
                  dist_ngram, dist_ngram_pcnt,
                  dist_phon, dist_phon_pcnt
                  # ... other metrics ...
                  )
  
  return(output)
}

# Sample Degradations ----
# ABOUT: returns positional indices of observations to keep for sample 

sample_degradations_simple = function(df, n_p_samples = 100){
  # generate random sample
  if(n_p_samples < 1){
    # interpret as percentage, based on pre cut-off count
    keep = tibble(keep) %>% 
      sample_frac(tbl = ., size = n_p_samples) %$% 
      keep
    
  }else{
    # interpret as count
    if(n_p_samples > df.dim[1]){n_p_samples = df.dim[1]}
    keep = tibble(keep) %>% 
      sample_n(tbl = ., size = n_p_samples) %$% 
      keep
  }
  
  return(keep)
  
  
}

