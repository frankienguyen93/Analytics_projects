#Loading the dataset

df <- read.csv(file.choose(),
               header = TRUE)

set.seed(123)

#Removing meaningless variables

df1 <- df[, -c(1, 2, 15:17, 22:24)]

df2 <- df1

#Histograms for log-normally  distributed variables

par(mfrow = c(1, 2))

hist(df1$price,
     breaks = 50,
     main = "Histogram of House Prices",
     xlab = "Price")

hist(log(df1$price),
     breaks = 50,
     main = "Histogram of Log of Prices",
     xlab = "Log of Price")

hist(df1$sqft_living,
     breaks = 50,
     main = "Histogram of Square footage",
     xlab = "Square Footage")

hist(log(df1$sqft_living),
     breaks = 50,
     main = "Histogram of Log of Square footage",
     xlab = "Log of Square footage")

#Transformations

df1$price <- log(df1$price)

colnames(df1)[1] <- "log_price"

df1$sqft_living <- log(df1$sqft_living)

colnames(df1)[4] <- "log_sqft_living"

#Linear Regression before Lasso

lm <- lm(log_price ~ .,
         data = df1)

summary(lm)

#Lasso Regression

dm <- as.matrix(df1)

require(glmnet)

response <- dm[, 1]

predictors <- dm[, -1]

cv <- cv.glmnet(x = predictors,
                y = response,
                alpha = 1,
                nlambda = 500)

lr <- glmnet(x = predictors,
             y = response,
             alpha = 1,
             lambda = cv$lambda.1se)

lr$beta

df3 <- as.data.frame(dm[, -c(16, 18)])

#Linear Regression after Lasso

lm1 <- lm(log_price ~ .,
          data = df3)

summary(lm1)

#Baseline Linear Regression Model

lm2 <- lm(formula = price ~ bedrooms + sqft_living + waterfront + view + condition + grade  + lat + age,
         data = df2)

summary(lm2)

#Ridge Regression

kc <- df2

row.number <- sample(x = 1:nrow(kc),
                     size = 0.80 * nrow(kc))

train = kc[row.number, ]

test = kc[-row.number, ]

price <- kc$price

kc.mat <- model.matrix(price ~ bedrooms + sqft_living + waterfront + view + condition + grade  + lat + age, kc)[,-1]

train.mat <- kc.mat[row.number,]

test.mat <- kc.mat[-row.number,]

price.train <- price[row.number]

price.test <- price[-row.number]

ridge.cv <- cv.glmnet(x= train.mat, y = price.train, alpha = 0)

ridge.cv$lambda.min #26154.8

ridge.pred <- predict(ridge.cv, test.mat, s= ridge.cv$lambda.min)

#Function for Rmse
rmse <- function(actual, predict){
  return(sqrt(mean(abs(actual - predict)^2)))
}

rmse(price.test, ridge.pred) #186965

sst <- sum((mean(price.test) - price.test)^2)
sse <- sum((ridge.pred - price.test)^2)
rsq <- 1 - (sse / sst)
rsq #0.7016

#Linear Regression Model after Transformation

lm3 <- lm(formula = log_price ~ bedrooms + log_sqft_living + waterfront + view + condition + grade  + lat + age,
         data = df1)

summary(lm3)

#Predict

row.number <- sample(x = 1:nrow(df1),
                     size = 0.80 * nrow(df1))

train = df1[row.number, ]

test = df1[-row.number, ]

#Function for Prediction and Result

result <- function(predicted){
  
  observed <- test$log_price
  
  SSE <- sum((observed - predicted) ^ 2)
  
  SST <- sum((observed - mean(observed)) ^ 2)
  
  R2 <- 1 - SSE/SST
  
  accuracy <- accuracy(f = predicted, x = observed)
  
  cat("R2:", R2, "\n")
  
  return(accuracy)
  
}

predicted <- predict(lm3, newdata = test)

result(predicted)

#MODELS
#Stepwise

sm <- step(object = lm,
           direction = "both")

summary(sm)

#Predict

predict_sm <- predict(sm, newdata = test)

result(predict_sm)

#Optimization Gradient Boosting
library(gbm)

gbm <- gbm(log_price ~ bedrooms + log_sqft_living + waterfront + view + condition + grade  + lat + age,
           distribution = "gaussian",
           data=train,
           n.trees = 10000,
           interaction.depth = 3,
           shrinkage = 0.01)

par(mfrow = c(1, 1))

summary(gbm)

#Generating a Prediction matrix for each Tree

ntrees = seq(from=100 ,to=10000, by=100) #no of trees-a vector of 100 values

predmatrix<-predict(gbm,test,n.trees = ntrees)

#Calculating The Mean squared Test Error
test.error<-with(test,apply( (predmatrix-log_price)^2,2,mean))

#Plotting the test error vs number of trees

plot(ntrees , test.error , pch=19,col="blue",xlab="Number of Trees",ylab="Test Error", main = "Perfomance of Boosting on Test Set")

#adding the RandomForests Minimum Error line trained on same data and similar parameters

abline(h = min(test.error),col="red") #test.err is the test error of a Random forest fitted on same data

legend("topright",c("Minimum Test error Line for Random Forests"),col="red",lty=1,lwd=1)


#Generating a Prediction matrix for each Tree

predict_gbm<-predict(gbm,test,n.trees = 10000, type= "response")

result(predict_gbm)

# Optimization Random Forest

library(randomForest)

rdf <- randomForest(log_price ~ bedrooms + log_sqft_living + waterfront + view + condition + grade  + lat + age,
                    data = train,
                    importance = TRUE)

rdf

# Accessing the accuracy of result

pred_rdf <- predict(rdf, test, type ="class")

result(pred_rdf)

if(!require(tidyverse)){
  install.packages("tidyverse")
  library(tidyverse)
}