


# Preliminaries
# ------------------------------------------------------------------------------------------------------------
rm( list = ls() )

library( sqldf )



# Load data
# ------------------------------------------------------------------------------------------------------------
Prefix <- '~/Dropbox (Personal)/General/Math 2140/Code/Chapter 1/Binomial/'



# Simulate binomial draws
# ------------------------------------------------------------------------------------------------------------
N <- 1000

Binomial_10 <- data.frame( Trial = 1:N, Successes = rbinom( N, 100, 0.1 ), "Parameter" = "10 %" )

Binomial_20 <- data.frame( Trial = 1:N, Successes = rbinom( N, 100, 0.2 ), "Parameter" = "20 %" )

Binomial_30 <- data.frame( Trial = 1:N, Successes = rbinom( N, 100, 0.3 ), "Parameter" = "30 %" )

Binomial_40 <- data.frame( Trial = 1:N, Successes = rbinom( N, 100, 0.4 ), "Parameter" = "40 %" )

Binomial_50 <- data.frame( Trial = 1:N, Successes = rbinom( N, 100, 0.5 ), "Parameter" = "50 %" )

Data_Vertical <- rbind( Binomial_10, Binomial_20, Binomial_30, Binomial_40, Binomial_50 )



# Save
# ------------------------------------------------------------------------------------------------------------
write.csv( Data_Vertical, paste0( Prefix, 'Binomial.csv' ), row.names = FALSE, na = '' )

































