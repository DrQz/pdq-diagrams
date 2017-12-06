# Jackson network example
# Created by NJG on Saturday, March 7, 2009
# Updated by NJG on Friday, September 4, 2015

library(pdq)

# Arrival rate into the network:
arate <- 0.50
# Node service times:
stime <- c(1.0,2.0,1.0)
# Set up traffic eqns from network diagram:
# L1 = 0.5 + 0.2 L3
# L2 = 0.5 L1
# L3 = 0.5 L1 + 0.8 L2
# Rearrange the terms into matrix form:
#  1.0 L1 + 0.0 L2 - 0.2 L3 = 0.5
# -0.5 L1 + 1.0 L2 + 0.0 L3 = 0.0
# -0.5 L1 - 0.8 L2 + 1.0 L3 = 0.0
# All diagonal coeffs should be 1.0
# Map the coeffs into R matrices:
A <- matrix(c(1.0,0.0,-0.2, -0.5,1.0,0.0, -0.5,-0.8,1.0), 3, 3, byrow=TRUE)
B <- c(0.5,0.0,0.0)
# Solve for the local throughputs (L):
L <- solve(A,B)
# Use L matrix to calculate visit ratios at each router
v <- c(L[1]/arate, L[2]/arate, L[3]/arate)
# Service demands at each node:
sd <- c(v[1]*stime[1], v[2]*stime[2], v[3]*stime[3])
#
# Set up PDQ-R model of the Jackson network
#------------------------------------------
pdq::Init("Jackson Network in PDQ-R")
wname <- "Traffic"
rname <- c("Router1", "Router2", "Router3")

# Create the traffic arriving into the network
pdq::CreateOpen(wname, arate)
pdq::SetWUnit("Msg")
pdq::SetTUnit("Sec")
# Create network routers
for(i in 1:length(rname)) {
  pdq::CreateNode(rname[i], CEN, FCFS)
  pdq::SetDemand(rname[i], wname, sd[i])
}

pdq::Solve(CANON)
pdq::Report()

print("Check traffic eqns:")
cat(sprintf("L1: %f == %f: 0.5 + 0.2 L3\n", L[1], (0.5 + 0.2*L[3]), L[3]))
cat(sprintf("L2: %f == %f: 0.5 L1\n", L[2], (0.5*L[1])))
cat(sprintf("L3: %f == %f: 0.5 L1 + 0.8 L2\n", L[3], (0.5*L[1] + 0.8*L[2])))

sink("~/GitHub/PDQ/pdq-diagrams/jackson-rpt.txt")
pdq::Report()
sink()


