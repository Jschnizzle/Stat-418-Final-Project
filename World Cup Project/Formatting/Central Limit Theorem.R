


# Preliminaries
# ------------------------------------------------------------------------------------------------------------
rm( list = ls() )



# Load data
# ------------------------------------------------------------------------------------------------------------
Prefix <- '~/Dropbox (Personal)/General/Math 2140/Code/Chapter 2/Central Limit Theorem/'



# Simulate exponential population
# ------------------------------------------------------------------------------------------------------------
Population_Size <- 10000

Population_Lambda <- 10

Exponential_Size_Lambda <- rexp( Population_Size, Population_Lambda )



# Simulate sample mean when N is small
# ------------------------------------------------------------------------------------------------------------
Number_of_Samples <- 1000

Sample_Size_Small <- 3

Sample_Mean_N_Small <- rep( NA, Number_of_Samples )

for( i in 1:Number_of_Samples )
{
  Sample_Mean_N_Small[ i ] <- mean( sample( Exponential_Size_Lambda, Sample_Size_Small ) )
}

par( mfrow = c( 2, 1 ) )

hist( Exponential_Size_Lambda, xlim = c( 0, 1 ), br = 100 ); abline( v = 1/Population_Lambda, col = "red" )

hist( Sample_Mean_N_Small, xlim = c( 0, 1 ), br = 40 ); abline( v = 1/Population_Lambda, col = "red" )



# Simulate sample mean when N is large
# ------------------------------------------------------------------------------------------------------------
Number_of_Samples <- 1000

Sample_Size_Large <- 300

Sample_Mean_N_Large <- rep( NA, Number_of_Samples )

for( i in 1:Number_of_Samples )
{
  Sample_Mean_N_Large[ i ] <- mean( sample( Exponential_Size_Lambda, Sample_Size_Large ) )
}

par( mfrow = c( 2, 1 ) )

hist( Exponential_Size_Lambda, xlim = c( 0, 1 ), br = 100 ); abline( v = 1/Population_Lambda, col = "red" )

hist( Sample_Mean_N_Large, xlim = c( 0, 1 ), br = 10 ); abline( v = 1/Population_Lambda, col = "red" )


































