# ABOUT: Degradation Scenarios applicable to business names only

# Deg: Remove Business Designations ----
# ABOUT: Remove all spaces from the original name
dat = raw %>% filter(SDN_TYPE == "entity")

# apply degradation
business_designations = readLines(con = "ref-files/synonyms_business-designations.txt", warn = FALSE) %>% 
  str_split(string = ., pattern = "\\|") %>% 
  lapply(., trimws) %>% 
  unlist()

business_designations = business_designations[which(business_designations != "")] # drop empty entries
business_designations = business_designations[order(nchar(business_designations), decreasing = TRUE)] # sort by nchar to prevent duplication removal 
business_designations = paste0(" ", business_designations)

dat$test_name = dat$prepd_name
for(i in seq_along(business_designations)){
  # apply degradation
  dat$test_name = str_remove(string = dat$test_name, pattern = fixed(business_designations[i]))
}

# drop un-altered names
dat.drop = which(dat$prepd_name == dat$test_name) 
if(length(dat.drop) > 0L){
  dat = dat[-dat.drop, ]
}


# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]

# archive
deg = c(deg, "rm-biz-deg" = list(dat)) 

# Deg: Business Designation Synonym ----
# ABOUT: Replaces business designation with defined synonym
# ... see same-line entries in "ref-files/synonyms_business-designations.txt" 
dat = raw %>% filter(SDN_TYPE == "entity")

# apply degradation
business_designations = readLines(con = "ref-files/synonyms_business-designations.txt", warn = FALSE) %>% 
  str_split(string = ., pattern = "\\|") %>% 
  lapply(., trimws)

business_designations = business_designations[-which(sapply(sapply(business_designations, function(x){which(identical(x,""))}), length) > 0)] # drop empty lists elements
business_designations = lapply(business_designations, function(x){x[which(x!="")]}) # drop empty entries
business_designations = lapply(business_designations, function(x){paste0(" ", x)})

dat$test_name = dat$prepd_name
for(i in seq_along(dat$prepd_name)){
  # TODO: Speed this up, this loop is very slow because of all of the pattern matching
  # Execution clocked at: Time difference of 11.56615 secs
  
  # find best match
  designation_match = sapply(business_designations, function(d) {
    sapply(d, function(e) {
      grep(
        pattern = e,
        x = dat$test_name[i],
        fixed = TRUE,
        value = TRUE
      )
    })
  }) %>% unlist() %>% names() %>% unique()
  
  if(is.null(designation_match)){
    # no designation matched
    next
  }
  
  designation_match.nchar = nchar(designation_match)
  designation_match = designation_match[which.max(designation_match.nchar)]
  designation_match.location = sapply(business_designations, function(x){any(x == designation_match)}) %>% 
    which()
  
  designation_match.replacement = business_designations[designation_match.location] %>% unlist()
  designation_match.replacement = tibble(original = designation_match.replacement,
                                         clean = gsub(pattern = "[[:punct:]]", "", designation_match.replacement))
  
  designation_match.replacement = designation_match.replacement %>%
    # prevent replacement on between punctuated and non-punctuated versions e.g. "LLC" <> "L.L.C."
    filter(clean != unique(designation_match.replacement$clean[which(designation_match.replacement$original == designation_match)])) %$%
    original %>%
    # randomly pick a synonym candidate
    sample(x = ., size = 1)
  
  dat$test_name[i] = str_replace(string = dat$test_name[i], pattern = fixed(designation_match), replacement = fixed(designation_match.replacement))
  
}

# drop un-altered names
dat.drop = which(dat$prepd_name == dat$test_name) 
if(length(dat.drop) > 0L){
  dat = dat[-dat.drop, ]
}


# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]

# archive

deg = c(deg, "syn-biz-deg" = list(dat)) 

# Deg: Business Designation Replacement ----
# ABOUT: Replaces business designation with any other EXCEPT defined synonyms
# ... for synonyms, see same-line entries in "ref-files/synonyms_business-designations.txt" 
# ... probability of replacement candidate proportional to string distance from 
# .... original designation; i.e. the more different a candidate is, the higher the likelihood that it will
# .... be selected as the replacement value
dat = raw %>% filter(SDN_TYPE == "entity")

# apply degradation
business_designations = readLines(con = "ref-files/synonyms_business-designations.txt", warn = FALSE) %>% 
  str_split(string = ., pattern = "\\|") %>% 
  lapply(., trimws)

business_designations = business_designations[-which(sapply(sapply(business_designations, function(x){which(identical(x,""))}), length) > 0)] # drop empty lists elements
business_designations = lapply(business_designations, function(x){x[which(x!="")]}) # drop empty entries
business_designations = lapply(business_designations, function(x){paste0(" ", x)})

dat$test_name = dat$prepd_name
for(i in seq_along(dat$prepd_name)){
  # TODO: Speed this up, this loop is very slow because of all of the pattern matching
  # Execution clocked at: Time difference of 18.91292 secs
  
  # find best match
  designation_match = sapply(business_designations, function(d) {
    sapply(d, function(e) {
      grep(
        pattern = e,
        x = dat$test_name[i],
        fixed = TRUE,
        value = TRUE
      )
    })
  }) %>% unlist() %>% names() %>% unique()
  
  if(is.null(designation_match)){
    # no designation matched
    next
  }
  
  designation_match.nchar = nchar(designation_match)
  designation_match = designation_match[which.max(designation_match.nchar)]
  designation_match.location = sapply(business_designations, function(x){any(x == designation_match)}) %>% 
    which()
  
  designation_match.replacement = business_designations[-designation_match.location] %>% unlist() # exclude synonyms
  designation_match.replacement = tibble(original = designation_match.replacement,
                                         dist = stringdist::stringdist(a = designation_match, original) # weighting
  ) %>%
    mutate(dist = dist/sum(dist)) %>% # weighting
    sample_n(tbl = ., size = 1, weight = dist) %$% # weighting
    original
  
  dat$test_name[i] = str_replace(string = dat$test_name[i], pattern = fixed(designation_match), replacement = fixed(designation_match.replacement))
  
}
rm(list = ls(pattern = "designation_match")) # clean-up

# drop un-altered names
dat.drop = which(dat$prepd_name == dat$test_name) 
if(length(dat.drop) > 0L){
  dat = dat[-dat.drop, ]
}

# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]


# archive
deg = c(deg, "replace-biz-deg" = list(dat)) 

