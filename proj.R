setwd("C:/users/54133/Desktop/projet")
mydata=read.csv("listings.csv",header = T  ,fill = TRUE)
mydata$host_since=as.POSIXlt(mydata$host_since)
mydata$year=substring(mydata$host_since,1,4)
mydata$year=2021-as.numeric(mydata$year)

names(mydata)
mydata$id=as.factor(mydata$id)
mydata$host_id=as.factor(mydata$host_id)
mydata$host_is_superhost=as.factor(mydata$host_is_superhost)
mydata$host_has_profile_pic=as.factor(mydata$host_has_profile_pic)
mydata$host_identity_verified=as.factor(mydata$host_identity_verified)
mydata$neighbourhood_cleansed=as.factor(mydata$neighbourhood_cleansed)
mydata$property_type=as.factor(mydata$property_type)
mydata$room_type=as.factor(mydata$room_type)
mydata$bathrooms_text=as.factor(mydata$bathrooms_text)
mydata$instant_bookable=as.factor(mydata$instant_bookable)
mydata$host_response_time=as.factor(mydata$host_response_time)
mydata$host_response_rate=substr(mydata$host_response_rate,1,nchar(mydata$host_response_rate)-1)
mydata$host_acceptance_rate=substr(mydata$host_acceptance_rate,1,nchar(mydata$host_acceptance_rate)-1)
mydata$host_acceptance_rate=as.numeric(mydata$host_acceptance_rate)
mydata$host_response_rate=as.numeric(mydata$host_response_rate)
mydata$price=substring(mydata$price,2,)
mydata$price=as.numeric(mydata$price)

write.csv(mydata, "donnees.csv")

#apres netoyer les donnees par sas#

mydata=read.csv("STAT.csv",header = T  ,fill = TRUE)
library(mclust)

fit = Mclust(mydata, G=1:20)
fit
str(mydata)
plot(fit)

library(NbClust)

NbClust(mydata, distance = "euclidean",
        min.nc = 2, max.nc = 10, 
        method = "kmeans") 

