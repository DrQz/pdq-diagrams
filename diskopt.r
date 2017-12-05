# Example for PDQ parser GV generator
# Created by NJG on Dec  4, 2017

library(pdq)

fastService <- 0.005 # seconds
slowService <- 0.015 # seconds
IOinterval  <- 0.006; # seconds
IOrate	    <- 1 / IOinterval

# Device names
FastDk	<- "FastDisk"
SlowDk	<- "SlowDisk"
# Work names
IOReqsF <- "fastIOs"
IOReqsS <- "slowIOs"

# Start ratio 3/4 based on speed of 15/5 ms
fastFrac <- 0.75

modelName <- "Disk IO Optimization"
cat(sprintf("Solving: %s ...\n", modelName))

dkf <- data.frame()

while(fastFrac < 1.0) {
    Init(modelName)

    CreateNode(FastDk, CEN, FCFS)
    CreateNode(SlowDk, CEN, FCFS)

    CreateOpen(IOReqsF, IOrate * fastFrac)
    CreateOpen(IOReqsS, IOrate * (1 - fastFrac))

    # Unlike the original example, we add a small
    # amount of the other workload on each disk
    SetDemand(FastDk, IOReqsF, fastService)
    SetDemand(FastDk, IOReqsS, 0)
    SetDemand(SlowDk, IOReqsS, slowService)
    SetDemand(SlowDk, IOReqsF, 0)
    
    Solve(CANON)

    fastRT <- GetResponse(TRANS, IOReqsF)
    slowRT <- GetResponse(TRANS, IOReqsS)
    meanRT <- (fastRT * fastFrac) + ((1 - fastFrac) * slowRT)
    
    # convert to  percentages 
    dkmets <- c(
     	fastFrac,
     	GetUtilization(FastDk, IOReqsF, TRANS),
     	GetUtilization(SlowDk, IOReqsS, TRANS),
     	fastRT * fastFrac * 100,
     	slowRT * (1 - fastRT) * 100,
     	meanRT * 100  
     )
     
     # add row to data frame
     dkf <- rbind(dkf, dkmets)
     fastFrac <- fastFrac +  0.01
}

names(dkf) <- c("f", "Uf", "Us", "Rf", "Rs", "Rt")
head(dkf)
print("Row with minimum RT")
minRow <- dkf[which(dkf$Rt == min(dkf$Rt)), ]
print(minRow)

plot(dkf$f, dkf$Rt, type="b",
     main=modelName,
     ylim=c(0,ceiling(max(dkf$Rt))),
     xlab="Fast fraction (f)",
     ylab="Response Times (Seconds)"
     )
abline(v=minRow$f, lty="dashed")
lines(dkf$f, dkf$Rs, col="green")
lines(dkf$f, dkf$Rf, col="red")

sink("~/GitHub/PDQ/pdq-diagrams/diskopt-rpt.txt")
pdq::Report()
sink()


