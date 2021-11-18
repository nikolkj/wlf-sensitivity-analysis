# ABOUT: Degradation Scenarios applicable to all names

# Source Checks ----
# TODO: 'header check' should be generalized if using more than just OFAC SDN and CONS lists

# Deg: Concatenations ----
# ABOUT: Remove all spaces from the original name
dat = raw

# apply degradation
dat$test_name = gsub(pattern = "\\s+", replacement = "", x = dat$prepd_name)

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
deg = c(deg, list(dat)) 

# Deg: Sticky Tokens ----
# ABOUT: Remove all spaces from the original name
dat = raw
dat = dat[str_detect(string = dat$prepd_name, pattern = " "),] # drop single token names

# apply degradation
dat$test_name = sapply(seq(1:length(dat$prepd_name)), function(x){
  name = dat$prepd_name[x]
  spn  = str_count(name ,"\\s+") # Count Spaces
  spn.select = sample(c(1:(spn-1)), size = 1) # Randomly select number of spaces to drop, do not drop all
  
  spn.pos = str_locate_all(name ,"\\s+") # Find Spaces
  spn.pos = spn.pos[[1]][sample(c(1:spn), size = spn.select),1] # Select which spaces to clip
  
  return( paste(str_split(string = name, pattern = "", simplify = TRUE)[1, -spn.pos], collapse = "") )
})  

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
deg = c(deg, list(dat)) 

# Deg: Symbol Stripping ----
# ABOUT: Replaces alphabetic characters with visually similar symbolics
dat = raw

# load reference
source("ref-files/stripping_map.R") # loads map; var 'strip_map'

# apply degradation
dat$test_name = sapply(dat$prepd_name, function(name){
  name = as.character(str_split(string = name, pattern = "", simplify = TRUE))
  name.swap = which(name %in% names(strip_map)) # select letter-indeces qualifying for a swap
  name[name.swap] = sapply(name.swap, function(letter){
    name[letter] = ifelse(test = sample(2,1) == 1, # 50% chance of swap, adjust as necessary
                          yes  = (strip_map[[name[letter]]][sample(length(strip_map[[name[letter]]]), size = 1)]),
                          no   = name[letter])
  }) 
  return(paste0(name, collapse = ""))
  
})

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
deg = c(deg, list(dat)) 

# Deg: Long Name Truncation ----
# ABOUT: Truncate long-names to 35 characters
dat = raw

# apply degradation
dat$test_name = str_sub(string = dat$prepd_name, end = 35L)
dat = dat[-which(dat$prepd_name == dat$test_name),] # drop un-altered names

# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]

# archive
deg = c(deg, list(dat)) 

# Deg: Random Word Truncation ----
# ABOUT: Randomly Truncates Tokens
# ... weighted by the number of tokens in a name
dat = raw

# apply degradation
  # tokenize
  test_name = str_split(string = dat$prepd_name, pattern = "\\s+")

  # probability of token truncation
  test_name_len = sapply(test_name, length)
    assertthat::noNA(test_name_len)
  max_len = max(test_name_len)
  scale_param = 1.5 # adjustable, recommended range [1.5,3]
  prob_default_trunc = (test_name_len/(max_len * scale_param))
  
  # plot(test_name_len,sapply(prob_default_trunc, sum)) # probability plot: NumberTokens v ProbTruncation
  
  rm(max_len, scale_param) # clean-up

for(i in seq_along(test_name)){
  
  trunc_flag = sample(x = c(1,0), replace = TRUE, size = test_name_len[i], 
                      prob = c(prob_default_trunc[i], (1-prob_default_trunc[i])))
  if(1 %in% trunc_flag){
    for(j in seq_along(test_name[[i]])){
      if(trunc_flag[j] == 1L){
        # truncate token
        # ... only applied when truncated token has more than 2 characters
        trunc_token = str_sub(string = test_name[[i]][j], 
                              end = sample(c(2:(nchar(test_name[[i]][j])-2)), size = 1))
        test_name[[i]][j] = case_when(is.na(trunc_token) ~  test_name[[i]][j], # control for NAs
                                      nchar(trunc_token) < 2 ~  test_name[[i]][j], # control for length
                                      TRUE ~ trunc_token
                                      )
        
      }else{
        next # token was not selected for truncation
      }
    }
    
  }else{
    next # no tokens were flagged for truncation
  }
  
  
  
}

dat$test_name = sapply(test_name, paste, collapse = " ")

# drop un-altered names
dat.drop = which(dat$prepd_name == dat$test_name) 
if(length(dat.drop) > 0L){
  dat = dat[-dat.drop, ]
}

rm(trunc_token, i, j, test_name, trunc_flag, prob_default_trunc, test_name_len) # clean-up

# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]

# archive
deg = c(deg, list(dat)) 

# Deg: Random Token Drop ----
# ABOUT: Drop random words from the name
# ... inversely weighted by number of characters in the name
# ... probability based on length of other tokens in the name
# ... unless all tokens are short and the overwrite is applied

dat = raw

# apply degradation
# tokenize
test_name = str_split(string = dat$prepd_name, pattern = "\\s+")

  # probability of token truncation
  test_name_len = sapply(test_name, nchar)
  assertthat::noNA(unlist(test_name_len))
  max_len = lapply(test_name_len, function(x) {
    m = max(x)
    if(m < 9){
      # overwrite if all tokens are short, adjustable
      # median token length = 6 char
      # mean + 1std = 85% ~= 9 char
      # ... choose one
      m = 9
    }
    
    return(m)
  })
  
  # scale_param = 1 # adjustable, recommended range [1.5,3]
  prob_default_drop = test_name_len # pre-allocate
  for(i in seq_along(prob_default_drop)){
    prob_default_drop[[i]] = 1 - (test_name_len[[i]] / max_len[[i]])
  }
  
  # plot(unlist(test_name_len), unlist(prob_default_drop)) # probability plot: TokenLength v ProbDrop
  rm(max_len) # clean-up

cut_off_param = 0.65 # adjustable, can't drop more than this % of tokens
for(i in seq_along(test_name)){
  
  drop_flag = sapply(prob_default_drop[[i]], function(x) {
    # flag tokens to drop based on relative probability
    sample(
      x = c(1, 0),
      size = 1,
      replace = TRUE,
      prob = c(x, c(1 - x))
    )
  })
  
  if(1 %in% drop_flag & (sum(drop_flag)/length(drop_flag)) < cut_off_param ){
    # drop tokens
    test_name[[i]] = test_name[[i]][as.logical(abs(drop_flag - 1))]
    
  }else{
    next # no tokens were flagged for drop
  }
  
}

dat$test_name = sapply(test_name, paste, collapse = " ")

# drop un-altered names
dat.drop = which(dat$prepd_name == dat$test_name) 
if(length(dat.drop) > 0L){
  dat = dat[-dat.drop, ]
}

rm(i, test_name, drop_flag, prob_default_drop, test_name_len) # clean-up

# calculate distances
dat = bind_cols(dat, degDistance(prepd_name = dat$prepd_name, test_name = dat$test_name))

# calculate metrics (e.g. original name length)
# TODO ^

# sample
dat = select(.data = dat, grep(pattern = "dist", x = names(dat))) %>% 
  sample_degradations_simple(df = .) %>% 
  dat[.,]

# archive
deg = c(deg, list(dat)) 