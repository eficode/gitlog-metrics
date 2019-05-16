#!/usr/bin/env Rscript

### Load up requirements ###

#  install.packages("tidyverse")
library(tidyverse)
library(lubridate)
library(RColorBrewer)

source(file="multiplot.R")

# Get better color scheme

qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))

# Theme settings for plots

commontheme <- theme(legend.title = element_blank(),
                     legend.position = "right") +
  theme(legend.text = element_text(size = 6)) +
  theme(legend.key.size = unit(0.4, "line")) +
  theme(axis.text.x = element_text(size = 6, angle = 45, hjust = 1)) +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank()
  )

# To avoid overlapping, use position_dodge to move horizontally
pd <- position_dodge(5)

# List of ints to use in breaks #

int_breaks <- function(x, n = 5) pretty(x, n)[pretty(x, n) %% 1 == 0] 

### Get the data ###

datafolder <- Sys.getenv(c("DATA"))
if (datafolder == "") {
  print("No project given, exiting...")
  quit()
}
datafolder <- paste0("out/", datafolder)

imgdir <- paste0(datafolder,"/img/")
dir.create(imgdir, recursive = TRUE, showWarnings = FALSE)

metricAbsChurn = read.csv(paste0(datafolder,"/data/abs-churn.csv"))
metricAbsChurn <- mutate(metricAbsChurn, week = cut(ymd(date), breaks = "week", start.on.monday = TRUE))
metricAbsChurnSel <- metricAbsChurn %>%
  select(-commits, -date) %>%
  gather(added, deleted, -week)

metricAuthorChurn = read.csv(paste0(datafolder,"/data/author-churn.csv"))
metricAuthorChurn = read.csv(paste0(datafolder,"/data/author-churn.csv"))
metricEntityOwnership = read.csv(paste0(datafolder,"/data/entity-ownership.csv"))

metricAge = read.csv(paste0(datafolder,"/data/age.csv"))
metricAge <- mutate(metricAge, folder = sapply(strsplit(as.character(metricAge$entity), "/") , "[", 1))
metricAge$folder[metricAge$entity == metricAge$folder] <- "/"
metricAge <- mutate(metricAge, subfolder = paste0(folder, "/", sapply(strsplit(as.character(metricAge$entity), "/") , "[", 2)))
metricAge$subfolder[metricAge$folder == "/"] <- "/"

metricAuthorsPerModule = read.csv(paste0(datafolder,"/data/authors-per-module.csv"))
metricAuthorsPerModule <- mutate(metricAuthorsPerModule, folder = sapply(strsplit(as.character(metricAuthorsPerModule$entity), "/") , "[", 1))
metricAuthorsPerModule$folder[metricAuthorsPerModule$entity == metricAuthorsPerModule$folder] <- "/"
metricAuthorsPerModule <- mutate(metricAuthorsPerModule, subfolder = paste0(folder, "/", sapply(strsplit(as.character(metricAuthorsPerModule$entity), "/") , "[", 2)))
metricAuthorsPerModule$subfolder[metricAuthorsPerModule$folder == "/"] <- "/"

maxAuthorsPerModule <- aggregate(metricAuthorsPerModule$n.authors, by=list(folder=metricAuthorsPerModule$folder), FUN=max)
maxAuthorsPerModule <- plyr::rename(maxAuthorsPerModule, c("x"="max_authors"))

metricEntityChurn = read.csv(paste0(datafolder,"/data/entity-churn.csv"))
metricEntityChurn <- mutate(metricEntityChurn, folder = sapply(strsplit(as.character(metricAge$entity), "/") , "[", 1))
selectedEntityChurn <- subset(metricEntityChurn, metricEntityChurn$commits>30)

metricCoupling = read.csv(paste0(datafolder,"/data/coupling.csv"))



# -------------------------------------------------- #
## P1.0 - commits/week ##

p10 <- ggplot(data = metricAbsChurn, aes(x = week)) + commontheme +
  geom_col(aes(y = commits), fill="Blue") +
  ggtitle("P1.0 - commits/week")
p10

# Export the plot
#png(paste(imgdir, "/", "p1.0.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
#p10
#dev.off()

# -------------------------------------------------- #
## P1.1 - commits/week ##
  
p11 <- ggplot(data = metricAbsChurnSel, aes(x = week)) + commontheme +
  geom_col(aes(y = deleted, fill=added), position="dodge", show.legend=FALSE) +
  ggtitle("P1.1 - absolute churn/week (added/deleted lines of code) - big bang or steady flow?") +
  scale_fill_manual("legend", values = c("added" = "darkgreen", "deleted" = "red")) +
  ylab("Lines of code") +
  xlab("Week")
p11


# Export the plot
png(paste(imgdir, "/", "p1.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
multiplot(p10, p11, cols=1)
#p11
dev.off()

# -------------------------------------------------- #
## P2 - commits/user ##

p2 <- ggplot(data = metricAuthorChurn, aes(x = author)) + commontheme +
  geom_col(aes(y = commits)) +
  xlab("author") +
  ggtitle("P2 - commits/user")
p2

# Export the plot
png(paste(imgdir, "/", "p2.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p2
dev.off()

# -------------------------------------------------- #
## P3 - code ownership ##

p2 <- ggplot(data = metricAuthorChurn, aes(x = author)) + commontheme +
  geom_col(aes(y = commits, fill=commits), show.legend=FALSE) +
  xlab("author") +
  ggtitle("P2 - commits/user")
p2
p3 <- ggplot(data = metricEntityOwnership, aes(x = author)) + commontheme +
  geom_histogram(stat="count") +
  ylab("number of files") +
  ggtitle("P3 - code ownership")
p3
#multiplot(p2, p3, cols=1)

# Export the plot
png(paste(imgdir, "/", "p3.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p3
#multiplot(p2, p3, cols=1)
dev.off()

# -------------------------------------------------- #
## P4 - code age ##

p4 <- ggplot(data = metricAge, aes(x = age.months)) + commontheme +
  geom_histogram(aes(fill=folder), position = "stack", bins = length(unique(metricAge$age.months))) +
  ylab("number of files") +
  xlab("months since last change") +
  ggtitle("P4 - code age") +
  scale_fill_manual(values=col_vector) +
  guides(fill=guide_legend(ncol=1))
p4

# Export the plot
png(paste(imgdir, "/", "p4.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p4
dev.off()

# -------------------------------------------------- #
## P5 - authors per module ##

p5 <- ggplot(data = metricAuthorsPerModule, aes(x = n.authors)) + commontheme +
  geom_histogram(stat="count") +
  ylab("number of files") +
  xlab("number of authors") +
  ggtitle("P5 - authors per file - experts or shared knowledge?")
p5

# Export the plot
png(paste(imgdir, "/", "p5.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p5
dev.off()

# -------------------------------------------------- #
## P5b - authors per folder ##

p5b <- ggplot(data = maxAuthorsPerModule, aes(x = folder)) + commontheme +
  geom_col(aes(y = max_authors)) +
  ylab("number of authors") +
  ggtitle("P5b - authors per folder")
p5b

# Export the plot
png(paste(imgdir, "/", "p5b.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p5b
dev.off()

# -------------------------------------------------- #
## P6 ##

p6 <- ggplot(data = selectedEntityChurn, aes(x = reorder(entity, desc(commits)))) + commontheme +
  geom_col(aes(y = commits)) +
  xlab("entity") +
  ggtitle("P6 - commits/week")
p6


# Export the plot
#png(paste(imgdir, "/", "p6.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
#p6
#dev.off()


# -------------------------------------------------- #
## P7 ##
# x number of changes
# y number of authors
## authors-per-module: entity,n-authors,n-revs
# size = age
## age: entity,age-months
# color = Coupling
## coupling: entity,coupled,degree,average-revs

#metricAuthorsPerModule
#metricAge
#metricCoupling

p7 <- ggplot(data = metricAuthorsPerModule, aes(x = n.authors)) + commontheme +
  geom_point(aes(y = n.revs, color = folder), position=position_jitter(width=.49,height=.49)) +
  ggtitle("P7 - complexity (revisions vs. authors)") +
  scale_color_manual(values = col_vector) +
  guides(color=guide_legend(ncol=1))
p7


# Export the plot
png(paste(imgdir, "/", "p7.png", sep = ""), width = 5000, height = 3000, res = 550, pointsize = 10)
p7
dev.off()

