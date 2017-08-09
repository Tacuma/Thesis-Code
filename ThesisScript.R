#Tacuma Solomon
#Thesis - Identifying Subgroups of Minority Diabetes Type II Data Using Cluster Analysis
#R Code

#install.packages commands
install.packages("klaR")
install.packages("cluster")
install.packages("Rtsne")
install.packages("magrittr")
install.packages("stats")
install.packages("ggplot2")
install.packages("dplyr")

#loading packages into R
library(klaR)
library(magrittr)
library(cluster)
library(Rtsne)
library(ggplot2)
library(dplyr)


diabetes_data -> read_csv(file.choose()) 
str(diabetes_data) 

diabetes_data$PATIENT_NUMBER<- as.character(diabetes_patient$PATIENT_NUMBER)

#Experminenting with Different Transformations of the Data

  #Use the code below to cluster and visualize with PAM
#Experiment - Conversion of entire Dataset to numeric 
dnum <- diabetes_data
dnum$GENDER <- as.numeric(dnum$GENDER)
dnum$RACE <- as.numeric(dnum$RACE)
dnum$RELIGION <- as.numeric(dnum$RELIGION) 
dnum$MARITAL_STATUS <- as.numeric(dnum$RACE)
dnum$CONCEPT_CD <- NULL


#Experiment - Conversion by removing factors
d_nofactors <- diabetes_data[-c(2, 3, 5, 6, 9)]

#Experiment - Conversion by removing gender
d_nogender <- diabetes_data
d_nogender$GENDER <- NULL 

#Script to create dissimilarity Matrix (Use PAM to cluster, and TSNE scripts below to visualize)
gower_dist <- daisy(dnum[, -1],
                    metric = "gower")



## Kmodes Algorithm ##
######################


dd_random <- diabetes_data[sample(nrow(diabetes_data)),]
dd_for_kmodes <- na.omit(dd_random)

#2 Clusters
cluster_fit <- kmodes(dd_for_kmodes[,-1], 2, iter.max = 10, weighted = FALSE)
#3 Clusters
cluster_fit <- kmodes(dd_for_kmodes[,-1], 3, iter.max = 10, weighted = FALSE)
#4 Clusters
cluster_fit <- kmodes(dd_for_kmodes[,-1], 4, iter.max = 10, weighted = FALSE)
#5 Clusters
cluster_fit <- kmodes(dd_for_kmodes[,-1], 5, iter.max = 10, weighted = FALSE)

#Output Summary For Knodes # Run for each version of cluster_fit
cluster_results <- dd_for_kmodes %>%
  dplyr::select(-PATIENT_NUMBER) %>%
  mutate(cluster = cluster_fit$cluster) %>%
  group_by(cluster) %>%
  do(the_summary = summary(.))

cluster_results$the_summary
cluster_fit$modes



## PAM Algorithm ##
###################


#Gower Dissimilarity Matrix
gower_dist <- daisy(diabetes_data[, -1],
                    metric = "gower",
                    type = list(symm = 1))

 
#2 Clusters 
pam_fit <- pam(gower_dist, diss = TRUE, k = 2)
#3 Clusters 
pam_fit <- pam(gower_dist, diss = TRUE, k = 3)
#4 Clusters 
pam_fit <- pam(gower_dist, diss = TRUE, k = 4)
#5 Clusters 
pam_fit <- pam(gower_dist, diss = TRUE, k = 5)

#Visualization function for each cluster - Dimensionality Reduction using T-SNE
tsne_obj <- Rtsne(gower_dist, is_distance = TRUE)

tsne_data <- tsne_obj$Y %>%
  data.frame() %>%
  setNames(c("X", "Y")) %>%
  mutate(cluster = factor(pam_fit$clustering),
         name = diabetes_data$PATIENT_NUMBER)

ggplot(aes(x = X, y = Y), data = tsne_data) +
  geom_point(aes(color = cluster))



## HClust Algorithm ##
######################

library(stats)
library(cluster)

#Gower Dissimilarity Matrix
gower_dist <- daisy(diabetes_data[, -1],
                    metric = "gower",
                    type = list(symm = 1))

d.hclust = hclust(gower_dist)
plot(d.hclust)

#2 Clusters
dgroup <- cutree(d.hclust, 2)
#3 Clusters
dgroup <- cutree(d.hclust, 3)
#4 Clusters
dgroup <- cutree(d.hclust, 4)
#5 Clusters
dgroup <- cutree(d.hclust, 5)



## DIANA Algorithm ###
######################

#Gower Dissimilarity Matrix
gower_dist <- daisy(diabetes_data[, -1],
                    metric = "gower",
                    type = list(symm = 1))

d.dclust = diana(gower_dist)
plot(d.dclust)

#2 Clusters
hgroup <- cutree(d.dclust, 2)
#3 Clusters
hgroup <- cutree(d.dclust, 3)
#4 Clusters
hgroup <- cutree(d.dclust, 4)
#5 Clusters
hgroup <- cutree(d.dclust, 5)

