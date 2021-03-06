# notes

## 5.1 - model divorce rate as a function of the (standarized) median age of marriage
library(rethinking)
data("WaffleDivorce")
d <- WaffleDivorce

d$MedianAgeMarriage.standardized <- (d$MedianAgeMarriage - mean(d$MedianAgeMarriage)) / sd(d$MedianAgeMarriage)
m5.1 <- map(
  alist(
    Divorce ~ dnorm(mean = mu, sd = sigma),
    mu <- alpha + beta.A * MedianAgeMarriage.standardized,
    alpha ~ dnorm(mean = 10, sd = 10),
    beta.A ~ dnorm(mean = 0, sd = 1),
    sigma ~ dunif(min = 0, max = 10)
  ),
  data = d
)

## 5.2 - plot the confidence interval around the mean of the Guassian
median.age.marriage.seq <- seq(from = -3, to = 3.5, length.out = 30)
mu <- link(m5.1, data = data.frame(MedianAgeMarriage.standardized=median.age.marriage.seq))
mu.PI <- apply(X = mu, MARGIN = 2, FUN = PI)

plot(Divorce ~ MedianAgeMarriage.standardized, data = d, col=rangi2)
abline(m5.1)
shade(object = mu.PI, lim = median.age.marriage.seq)

## 5.3 - model divorce rate as a function of the (standardized) marriage rate
d$Marriage.standardized <- (d$Marriage - mean(d$Marriage)) / sd(d$Marriage)
m5.2 <- map(
  alist(
    Divorce ~ dnorm(mean = mu, sd = sigma),
    mu <- alpha + beta.R * Marriage.standardized,
    alpha ~ dnorm(mean = 10, sd = 10),
    beta.R ~ dnorm(mean = 0, sd = 1),
    sigma ~ dunif(min = 0, max = 10)
  ),
  data = d
)

## 5.4 - model divorce rate as a function of both marriage rate and median age of marriage
m5.3 <- map(
  alist(
    Divorce ~ dnorm(mean = mu, sd = sigma),
    mu <- alpha + beta.median.age.marriage * MedianAgeMarriage.standardized + beta.marriage.rate * Marriage.standardized,
    alpha ~ dnorm(mean = 10, sd = 10),
    beta.median.age.marriage ~ dnorm(mean = 0, sd = 1),
    beta.marriage.rate ~ dnorm(mean = 0, sd = 1),
    sigma ~ dunif(min = 0, max = 10)
  ),
  data = d
)

## 5.6 - model marriage rate as a function of median age of marriage
m5.4 <- map(
  alist(
    Marriage.standardized ~ dnorm(mean = mu, sd = sigma),
    mu <- alpha + beta.median.age.marriage * MedianAgeMarriage.standardized,
    alpha ~ dnorm(mean = 0, sd = 10),
    beta.median.age.marriage ~ dnorm(mean = 0, sd = 1),
    sigma ~ dunif(min = 0, max = 10)
  ),
  data = d
)

## 5.7 - compute marriage rate residuals
mu <- coef(m5.4)['alpha'] + coef(m5.4)['beta.median.age.marriage'] * d$MedianAgeMarriage.standardized
marriage.rate.residuals <- d$Marriage.standardized - mu

## 5.8 - plot residuals
plot(Marriage.standardized ~ MedianAgeMarriage.standardized, data = d, col=rangi2)
abline(m5.4)
for (i in 1:length(marriage.rate.residuals)) {
  x <- d$MedianAgeMarriage.standardized[i]
  y <- d$Marriage.standardized[i]
  lines( c(x, x), c(mu[i], y), lwd = .5, col = col.alpha("black", .7))
}

## 5.9 - create counterfactual plot for standardized marriage rate vs. divorce rate

# prepare new counterfactual data
median.age.marriage.average <- mean(d$MedianAgeMarriage.standardized)
marriage.rate.seq <- seq(from = -3, to = 3, length.out = 30)
pred.data <- data.frame(Marriage.standardized = marriage.rate.seq, MedianAgeMarriage.standardized = median.age.marriage.average)

# compute counterfactual mean divorce rate
mu <- link(m5.3, data=pred.data)
mu.mean <- apply(X = mu, MARGIN = 2, FUN = mean)
mu.PI <- apply(X = mu, MARGIN = 2, FUN = PI)

# simulate counterfactual divorce rate outcomes
divorce.rate.simulations <- sim(m5.3, data = pred.data, n = 1e4)
divorce.rate.simulations.PI <- apply(X = divorce.rate.simulations, MARGIN = 2, FUN = PI)

# plot results
plot(Divorce ~ Marriage.standardized, data = d, type = "n")
mtext("MedianAgeMarriage.standardized = 0")
lines(marriage.rate.seq, mu.mean)
shade(object = mu.PI, lim = marriage.rate.seq)
shade(object = divorce.rate.simulations.PI, lim = marriage.rate.seq)

## 5.10 - create counterfactual plot for standardized median age of marriage vs. divorce rate

# prepare new counterfactual data
marriage.rate.average <- mean(d$MedianAgeMarriage.standardized)
median.age.marriage.seq <- seq(from = -3, to = 3, length.out = 30)
pred.data <- data.frame(Marriage.standardized = marriage.rate.average, MedianAgeMarriage.standardized = median.age.marriage.seq)

# compute counterfactual mean divorce rate
mu <- link(m5.3, data = pred.data)
mu.mean <- apply(X = mu, MARGIN = 2, FUN = mean)
mu.PI <- apply(X = mu, MARGIN = 2, FUN = PI)

# simulate counterfactual divorce rate outcomes
divorce.rate.simulations <- sim(m5.3, data = pred.data, n = 1e4)
divorce.rate.simulations.PI <- apply(X = divorce.rate.simulations, MARGIN = 2, FUN = PI)

# plot results
plot(Divorce ~ MedianAgeMarriage.standardized, data = d, type = "n")
mtext("MedianAgeMarriage.standardized = 0")
lines(median.age.marriage.seq, mu.mean)
shade(object = mu.PI, lim = median.age.marriage.seq)
shade(object = divorce.rate.simulations.PI, lim = median.age.marriage.seq)

## 5.11 - simulate divorce rates using our original data
mu <- link(m5.3)
mu.mean <- apply(X = mu, MARGIN = 2, FUN = mean)
mu.PI <- apply(X = mu, MARGIN = 2, FUN = PI)
divorce.rate.simulations <- sim(m5.3, n = 1e4)
divorce.rate.simulations.PI <- apply(X = divorce.rate.simulations, MARGIN = 2, FUN = PI)

## 5.12 - plot actual divorce rates vs. observed divorce rates
plot( mu.mean ~ d$Divorce , col=rangi2 , ylim=range(mu.PI) ,
      xlab="Observed divorce" , ylab="Predicted divorce" )
abline( a=0 , b=1 , lty=2 )
for ( i in 1:nrow(d) )
  lines( rep(d$Divorce[i],2) , c(mu.PI[1,i],mu.PI[2,i]) ,
         col=rangi2 )

## 5.13
identify(x = d$Divorce, y = mu.mean, labels = d$Loc, cex = .8)

## 5.14 - compute and plot model residuals
divorce.rate.residuals <- d$Divorce - mu.mean
o <- order(divorce.rate.residuals)
dotchart( divorce.rate.residuals[o] , labels=d$Loc[o] , xlim=c(-6,5) , cex=0.6 )
abline( v=0 , col=col.alpha("black",0.2) )
for ( i in 1:nrow(d) ) {
  j <- o[i] # which State in order
  lines( d$Divorce[j]-c(mu.PI[1,j],mu.PI[2,j]) , rep(i,2) )
  points( d$Divorce[j]-c(divorce.rate.simulations.PI[1,j], divorce.rate.simulations.PI[2,j]), rep(i,2), pch=3 , cex=0.6 , col="gray" )
}

## 5.16
data(milk)
d <- milk
str(d)

## 5.62
data(cars)
glimmer(dist ~ speed, data = cars)
