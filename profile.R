#' Create a Deck of Playing Cards
#' 
#' @description
#' This function generates a deck of playing cards.
#'
#' @param num An integer specifying the number of decks to create (default is 1).
#' 
#' @return A data frame representing a deck of playing cards with columns for values, suits, lookup, and points.
#' 
#' @details
#' The deck consists of 52 cards, including numeric values from 2 to 10 and face cards (A, Q, K, J) for each of the four suits (Spades, Clubs, Diamonds, Hearts).
#' Each card has a unique identifier obtained by concatenating its value and suit.
#' Numeric values are assigned points equal to their face value, while face cards (Q, K, J) are assigned 10 points.
#' @export
#' @examples
#' create_deck()
#' create_deck(2)
#' 
create_deck <- function(num = 1) {
  deck <- expand.grid(values = c(2:10, "A", "Q", "K", "J"), suits = c("S", "C", "D", "H"), stringsAsFactors = FALSE)
  single <- deck
  if (num > 1) {
    for (i in 1:(num - 1)) {
      deck <- rbind(deck, single)
    }
  }
  deck$lookup <- paste0(deck$values, deck$suits)
  deck$point <- suppressWarnings(ifelse(!is.na(as.integer(as.character(deck$values))), as.integer(as.character(deck$values)),
                                        ifelse(deck$values %in% c("Q", "K", "J"), 10, 1)
  ))
  
  return(deck)
}


create_deck_optimized <- function(num = 1) {
  deck = expand.grid(values = c(2:10, "A", "Q", "K", "J"), suits = c("S", "C", "D", "H"), stringsAsFactors = FALSE)
  
  res = do.call("rbind", replicate(num, deck, simplify = FALSE)) 
  #res = data.table::rbindlist(replicate(num, deck, simplify = FALSE))
  
  res$lookup = paste0(res$values, res$suits)
  res$point = vector('integer', dim(res)[1])
  res$point[res$values %in% c("Q", "K", "J")] = 10
  res$point[res$values %in% c(2:10)] = 2:10
  res$point[res$values == "A"] = 1
  
  return(res)
}

Rprof()
system.time({res1 = create_deck(10000)})
Rprof(NULL)
summaryRprof()

Rprof()
system.time({res2 = create_deck_optimized(10000)})
Rprof(NULL)
summaryRprof()

all.equal(res1, res2)
