# From PPDQ book p.276
# Created by NJG on Tue Dec  5 16:14:18 2017


arrivals <- 15.36 / 3600  # 16 applicants per hour

#   // Branching probabilities appear in SetDemand times. 
p12 <- 0.30
p13 <- 0.70
p23 <- 0.20
p32 <- 0.10

# Visit ratios
v3 <- (p13 + p23 * p12) / (1 - p23 * p32)
v2 <- p12 + p32 * v3

# Initialize and solve the model 
Init("Passport Office")

CreateOpen("Applicant", arrivals)

CreateNode("Window1", CEN, FCFS)
CreateNode("Window2", CEN, FCFS)
CreateNode("Window3", CEN, FCFS)
CreateNode("Window4", CEN, FCFS)

SetDemand("Window1", "Applicant", 20.0)
SetDemand("Window2", "Applicant", 600.0 * v2)
SetDemand("Window3", "Applicant", 300.0 * v3)
SetDemand("Window4", "Applicant", 60.0)

Solve(CANON)
Report()

sink("~/GitHub/PDQ/pdq-diagrams/passport-rpt.txt")
pdq::Report()
sink()


