create_deck <- function(num = 1) {
  deck <- expand.grid(values = c(2:10, "A", "Q", "K", "J"), suits = c("S", "C", "D", "H"), stringsAsFactors = FALSE)
  single <- deck
  if (num > 1) {
    for (i in 1:(num - 1)) {
      deck <- rbind(deck, single)
    }
  }
  deck$lookup <- paste0(deck$values, deck$suits)
  deck$point <- suppressWarnings(ifelse(!is.na(as.numeric(as.character(deck$values))), as.numeric(as.character(deck$values)),
                                        ifelse(deck$values %in% c("Q", "K", "J"), 10, 1)
  ))
  
  return(deck)
}


create_deck_optimized <- function(num = 1) {
  deck <- expand.grid(values = c(2:10, "A", "Q", "K", "J"), suits = c("S", "C", "D", "H"), stringsAsFactors = FALSE)
  res = do.call("rbind", replicate(num, deck, simplify = FALSE)) 
  #res = data.table::rbindlist(replicate(num, deck, simplify = FALSE))
  
  res$lookup <- paste0(res$values, res$suits)
  res$point <- suppressWarnings(ifelse(!is.na(as.numeric(as.character(res$values))), 
                                       as.numeric(as.character(res$values)),
                                       ifelse(res$values %in% c("Q", "K", "J"), 10, 1)
  ))
  
  return(res)
}

Rprof()
res1 = create_deck(1000)
Rprof(NULL)
summaryRprof()

Rprof()
res2 = create_deck_optimized(10000)
Rprof(NULL)
summaryRprof()

all.equal(res1, res2)
