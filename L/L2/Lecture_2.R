Rprof(interval=.005)
x_pr = prcomp(x, retx = FALSE)
Rprof(NULL)
summaryRprof()$by.self[1:5, ]     



x = matrix(rnorm(1000*500), nrow=1000, ncol=500)

f = function(x) t(x) %*% x
g = function(x) crossprod(x)

library(rbenchmark)
benchmark(f(x), g(x))


n = 1e6
x = seq(0, 1, length.out=n)
f = function(x) exp(x^3 + 2.5*x^2 + 12*x + 0.12)
y1 = numeric(n)

set.seed(12345)
system.time({
  for(i in seq_len(n))
    y1[i] = f(x[i]) + rnorm(1)
})

set.seed(12345)
system.time({
  y2 = f(x) + rnorm(n)
})

all.equal(y1, y2)

v <- vector(length = 12)

memuse::memuse(x)
memuse::memuse(f)
memuse::memuse(y1)

# R, J, Mat, Fortran - column major - store things by columns
# Python and C - row major - store things by rows

mat <- matrix(1:12, nrow = 3, ncol = 4)
c(mat)
attr(mat, "dim")
dim(mat)

seq_along(10)


# laptop memory is slower cache
# cache is faster than memory
#cache miss - bigger piece from memory swap
# cache hit - smaller piece from memory swap


m = 1e3
n = 1e5
mat = matrix(runif(m*n), nrow = m)

system.time({
  result1 = vector("double", m)
  for(i in seq_len(m)) {
    result1[i] = mean(mat[i, ])
  }
})

system.time({tmat = t(mat)})

system.time({
  tmat = t(mat)
  result2 = vector("double", m)
  for(i in seq_len(m)) {
    result2[i] = mean(tmat[, i])
  }
})

# can create a physical chip that is faster than actual machine code

slow_function <- function(iterations) {
  for (i in 1:iterations) {
    # Perform some computation
    result <- 0
    for (j in 1:1000000) {
      result <- result + j
    }
  }
  return(result)
}

# Call the slow function with a large number of iterations
result <- slow_function(100)





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



system.time({res1 = create_deck(1000)})
system.time({res2 = create_deck_optimized(1000)})
all.equal(res1, res2)


Rprof()
res1 = create_deck(1000)
Rprof(NULL)
summaryRprof()

Rprof()
res2 = create_deck_optimized(10000)
Rprof(NULL)
summaryRprof()

all.equal(res1, res2)
