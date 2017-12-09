# Simplified PDQ model of autoscaling Tomcat server 
# Comprises 2 submodels:
# 1. Linear rising throughput: M/M/m node with m = 1 ... N_knee
# 2. Autoscaled region: M/M/1/N/N with S = 1/lambda_max for N < 500
# Advantages:
#  - Faster computation than FESC model
#  - Doesn't use probabilities like FESC
#  - Hence, no underflow NaN precision problems
# Created by NJG on Sat Dec  9 08:17:13 2017

library(pdq)

usrmax <- 500
nknee  <- 350
pdqx   <- TRUE # for PDQ network graph
smean  <- 0.45 # second
srate  <- 1 / smean
arate  <- 2.1 # per user
users  <- seq(100, usrmax, 50)
nu <- NULL
tp <- NULL
rt <- NULL

for (i in 1:length(users)) {
  
  if (users[i] <= nknee) {
    Arate  <- users[i] * arate  # total arrivals = m * λ 
    
    pdq::Init("Tomcat M/M/m")
    pdq::CreateOpen("requests", Arate)
    pdq::CreateMultiNode(users[i], "tcthreads", CEN, FCFS)
    pdq::SetDemand("tcthreads", "requests", smean)
    pdq::SetWUnit("Reqs")
    pdq::Solve(CANON)
    
    tp[i] <- pdq::GetThruput(TRANS, "requests")
    rt[i] <- pdq::GetResponse(TRANS, "requests")
    
    if (pdqx && users[i] == nknee) {
      # Output for PDQX
      sink("~/GitHub/PDQ/pdq-diagrams/tomcat2A-rpt.txt")
      pdq::Report()
      sink()
    }
    
  } else {
    Arate  <- nknee * arate # total arrivals = m * λ 
    
    pdq::Init("Tomcat M/M/1/N/N")
    pdq::CreateClosed("requests", TERM, users[i], 0)
    pdq::CreateNode("tcthreads", CEN, FCFS)
    pdq::SetDemand("tcthreads", "requests", 1/Arate)
    pdq::SetWUnit("Reqs")
    pdq::Solve(APPROX)
    
    tp[i] <- pdq::GetThruput(TERM, "requests")
    rt[i] <- pdq::GetResponse(TERM, "requests")
    
    if (pdqx && users[i] == usrmax) {
      # Output for PDQX
      sink("~/GitHub/PDQ/pdq-diagrams/tomcat2B-rpt.txt")
      pdq::Report()
      sink()
    }
  }
  
  nu[i] <- users[i]

}

plot(nu, tp, type="b", col="blue", 
     main="Tomcat Throughput",
     xlab="Threads",
     ylab="Throughput (RPS)",
     xlim=c(0,500),
     ylim=c(0,1000)
     )
abline(h=(nknee * arate), v=nknee, lty="dashed", col="gray")

plot(nu, rt, type="b", col="blue", 
     main="Tomcat Response Time",
     xlab="Threads",
     ylab="Response time (sec)",
     xlim=c(0,500),
     ylim=c(0,1.0)
)
abline(h=smean, v=nknee, lty="dashed", col="gray")

