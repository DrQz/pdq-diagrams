# florida.r is a CLOSED model
# From florida.pl in PPDQ book
# QNM diagram on p.241 
# Created by NJG on Tue Dec  5 14:50:17 2017

library(pdq)

STEP     <- 100
MAXUSERS <- 3000
think    <- 10	#seconds
srvts    <- c(0.0050,0.0035,0.0020) #seconds
Dmax     <- max(srvts)
Rmin     <- sum(srvts)

# Updated by NJG on Sunday, November 11, 2012
# Tabulate output using an R data frame.
df <- data.frame()

# iterate up to $MAXUSERS ...
# Updated by NJG on Saturday, November 110, 2012
# CreateClosed wants a REAL not an INT via as.numeric.
for (users in as.numeric(seq(1,MAXUSERS))) {
    Init("Florida Model")
    CreateClosed("benchload", TERM, users, think)
    CreateNode("Node1", CEN, FCFS)
    CreateNode("Node2", CEN, FCFS)
    CreateNode("Node3", CEN, FCFS)
    SetDemand("Node1", "benchload", srvts[1])
    SetDemand("Node2", "benchload", srvts[2])
    SetDemand("Node3", "benchload", srvts[3])

    Solve(APPROX)

    if ( (users == 1) || (users %% STEP == 0) ) {
    	# Combine selected PDQ metrics into a column vector
		metrics <- c( 
			users,
	    	pdq::GetThruput(TERM, "benchload"),
	    	users / (Rmin + think),
	    	1 / Dmax,
	    	users,
	    	pdq::GetResponse(TERM, "benchload"),
	    	Rmin,
	    	(users * Dmax) - think
	    )
	    
	    # Add vector as a row to the data frame
		df <- rbind(df, metrics)
    }
}

head(df)

#Report()

sink("~/GitHub/PDQ/pdq-diagrams/florida-rpt.txt")
pdq::Report()
sink()

