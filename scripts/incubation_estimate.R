devtools::load_all()

data <- read.table("../data-raw/Feb13 - In China.tsv", sep = "\t", header = TRUE)
cases.in.china <- data[c(1:161, 208:449), ]
library(devtools)
use_data(cases.in.china, overwrite = TRUE)

data$Confirmed <- date.process(data$Confirmed)
data$Arrived <- date.process(data$Arrived)
data$Symptom <- date.process(data$Symptom)
data$Initial <- date.process(data$Initial)
data$Hospital <- date.process(data$Hospital)

case72 <- data[72,]
data <- data[-c(72,19,95), ] # Don't know how to parse these infected date yet
data <- parse.infected(data)
case72$Infected_first <- date.process("15-Jan")
case72$Infected_last <- date.process("21-Jan")
data <- rbind(data, case72)
    
## Only consider cases with known symptom onset


## Only consider cases with known symptom onset, arrived on or before January 23
data <- subset(data, !is.na(Symptom))
## only consider cases arrived on or before January 23 
# data <- subset(data, Arrived <= 23+31) ## this will remove outside cases
## remove cases with no infection informations
# data <- subset(data, !(is.na(Arrived) & Infected_first == 1 & Infected_last == Symptom)) # remove cases with no information
# data <- subset(data, !(is.na(Arrived))) ## only consider outside cases
data <- subset(data, Infected_first != 1)
data <- subset(data, Infected_last != Symptom)

dim(data)
hist(data$Symptom - data$Infected_last)
hist(data$Symptom - data$Infected_first)
hist(data$Infected_last - data$Infected_first)
summary(data$Infected_last - data$Infected_first)

#' Compute the likelihood
#'
#' GT is a discretized distribution for the generation time
#'
infection.likelihood <- function(symptom, infected_first, infected_last, GT) {
    loglike <- 0
    for (i in 1:nrow(data)) {
        min.incub <- symptom[i] - infected_last[i]
        max.incub <- symptom[i] - infected_first[i]
        loglike <- loglike + log(sum(GT$GT[1 + (min.incub):(max.incub)])) ## should + 1 be included
    } 
    loglike 
}

myfun <- function(par) {
    GT <- R0::generation.time("gamma", par,truncate = 100);
    infection.likelihood(data$Symptom, data$Infected_first, data$Infected_last, GT)
}

fit <- optim(c(7.5, 3.4), myfun, control = list(fnscale = -1))
print(fit)

pars <- expand.grid(mean = seq(3, 15, 0.05), sd = seq(2, 8, 0.05))
pars$loglike <- apply(pars, 1, myfun)
print(pars[which.max(pars$loglike),]) ## print the grid-search MLE to terminal
pars$in.CR <- (pars$loglike > fit$value - qchisq(0.95, 1) / 2)

library(ggplot2)
p1 <- ggplot(pars) + aes(x = mean, y = sd, fill = loglike) + geom_tile()
# p1

p2 <- ggplot(pars) + aes(x = mean, y = sd, fill = in.CR) +geom_tile()
p2

