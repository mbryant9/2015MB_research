# goal, for the study: gene robustness is an important factor to explain aging or lifespan. 
# method:  why CV for gene expression
# CV = std/mean, a measurement of robustness, nosie to signal ratio.
# data science
# histograms 
# how many genes in yeast genomes
# what is microarray
# conslusions: CV are generally small, because yeast cells has a very small genome. 
# most of its genes are relatively indispensible for its homestatisis. 
# In comparison to human cells, how many genes, how many proteins. 

# do backgroud reading on gene-expression fluctuation

#2012 Nov 2

rm(list=ls())
require(GEOquery)

#http://www.ncbi.nlm.nih.gov/geo/browse/
#GEO2R 

myfiles = read.table("geo_GPL2529.tab", head=F, sep="\t")
myGSEs = as.character( myfiles[,1] )

#11:07->
for ( myGSE in myGSEs ) { 

  outfilename = paste( "output/", myGSE, "_log2CV.csv", sep='')
  
gset <- getGEO(myGSE, GSEMatrix =TRUE)
if (length(gset) > 1) idx <- grep("GPL90", attr(gset, "names")) else idx <- 1
gset <- gset[[idx]]

ex <- exprs(gset) #This is the expression matrix

sampleSizeFlag = 'largeSize'
if( length(ex[1,]) <= 5) { sampleSizeFlag='SmallSize'}

if( sampleSizeFlag == 'largeSize') {

#########
# Find out probes and ORFs
dictionary = gset@featureData@data[, c('ID', 'ORF')]  #This is a lookup table for probe ID and ORF 

ORFs = unique(as.character(dictionary$ORF))
yORFs = ORFs[grep( "Y\\w{2}\\d{3}.*", ORFs)]  #these are yeast ORFs
str(yORFs)
setdiff(ORFs, yORFs)

#yORFFlag = 'good'
#if (length(yORFs) < 1000) { yoORFFlag = 'toofewORFs' }

ORFs = yORFs

#########
# A simple approach to create an expression matrix with ORFs as row names
# This approach takes only one probe for each ORFs, which is often true for cDNA arrays

ex2 = ex[match(ORFs, dictionary$ORF), ]   
rownames(ex2) = ORFs
head(ex2) #Now, expression matrix is named by ORFs

##########
#Another approach is to calculate the average sigals for all the probes in the same ORFs
multipleORFs = NA;
ex3 = ex2 #This is just a template
# orf = 'YLR331C'
for (orf in ORFs) {
  myrows = as.character( dictionary$ID[dictionary$ORF==orf] )
  if (length(myrows) > 1) {
    print (orf)
    multipleORFs = c(multipleORFs, orf)
    ex[myrows, ] = apply(ex[myrows,], 2, mean) 
  }else {
    ex3[orf, ] = ex[myrows[1], ]
  }
}
#multipleORFs = multipleORFs[-1]

######
#normalizaion  
colSums = apply(ex3, 2, sum)
colSums/1E6
ex3norm = ex3
for( col in 1:length(ex3[1,])) {
  ex3norm[,col] = ex3[,col] * max(colSums) / sum(ex3[,col])
}
apply(ex3norm, 2, sum) / max(colSums)
ex3 = ex3norm 

#########
# now, have a look at the signals
hist(ex3[,1], br=100)
ex4 = log2(ex3)
hist(ex4[,3])
ex4[ex4<0] = NA #remove backgrounds

#############
#calculate coefficient of variation
myVar = apply( ex4, 1, FUN=function(x){var(x, na.rm=T)})
myStddev = sqrt(myVar)
myMean = apply( ex4, 1, FUN=function(x){mean(x, na.rm=T)})
myCV = myStddev / myMean
myarray= data.frame(cbind( myStddev, myMean, myCV))
myarray$ORF = ORFs
myarray = myarray[, c(4, 1:3)]
summary(myarray)

write.csv(myarray, outfilename, row.names=F)
test = read.csv( outfilename, colClasses = c('character', NA, NA, NA))
str(test)
hist(test$myCV, br=100)
hist(test$myStddev, br=100)
hist(test$myMean, br=100)

} else { # sampleSizeFlag == 'SmallSize', write an error file
  outfilename = paste( "output/", myGSE, "_log2CV.csv.", sampleSizeFlag, sep='')
  write.csv(x=rnorm(5), outfilename, row.names=F)  
}  # sampleSizeFlag

} #end of myGSEs loop


