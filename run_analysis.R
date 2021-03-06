## Data Science Coursera course

## 1. Merges the training and the test sets to create one data set.
## 2. Extracts only the measurements on the mean and standard deviation
##for each measurement.
## 3. Uses descriptive activity names to name the activities in the dataset
## 4. Appropriately labels the data set with descriptive activity names.
## 5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject.

## URL where to find the original zipfile
webDataSource <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

## Top working directory to contain the zip file and the unzipped contents
topDataDir  <- paste(ifelse(is.null(getwd()),".",getwd()), "/UCI\ HAR\ Dataset", sep="")

## Local filename with the zipped data
dataFileZipped <- "./UCI_HAR_Dataset.zip"
## Local filename for the final "tidy" data set
dataFileTidy <- "UCI_HAR_Dataset_Tidy.csv"

## "DetermineDataFiles" function that returns a list of all the data filenames
DetermineDataFiles <- function (source.data=webDataSource, result.top.dir=topDataDir,
                                local.data.zipped=dataFileZipped, work.with.zipped.data=FALSE) {
        if(work.with.zipped.data) {
                if(file.exists(result.top.dir) && !file_test("-d", result.top.dir)) {
                        stop("Top data directory location: \"",
                             result.top.dir, "\" meant for data processing, exists as ordinary file!\n")
                }
                if(!file.exists(result.top.dir)) {
                        dir.create(result.top.dir)
                }      
                if(!file.exists(local.data.zipped)) {
                        download.file(source.data, local.data.zipped, method="curl")
                }
                unzip(local.data.zipped, overwrite=TRUE, exdir=result.top.dir)
        } else {
                    result.top.dir,
                    "\"\n")
                if(file.exists(result.top.dir) && !file_test("-d", result.top.dir)) {
                        stop("Top data directory location: \"",
                             result.top.dir,
                             "\" used for data processing, is not a directory!\n")
                } else if(!file.exists(result.top.dir)) {
                        stop("Top data directory location: \"",
                             result.top.dir,
                             "\" used during data processing, does not exist!\n")
                }
        }
        data.files <- list(activities=paste(result.top.dir,"activity_labels.txt", sep="/"),
                           features  =paste(result.top.dir,"features.txt",sep="/"),
                           subject.test   =paste(result.top.dir,"test", "subject_test.txt", sep="/"),
                           subject.train  =paste(result.top.dir,"train", "subject_train.txt", sep="/"),
                           xtest     =paste(result.top.dir,"test", "X_test.txt", sep="/"),
                           xtrain    =paste(result.top.dir,"train", "X_train.txt", sep="/"),
                           ytest     =paste(result.top.dir,"test", "y_test.txt", sep="/"),
                           ytrain    =paste(result.top.dir,"train", "y_train.txt", sep="/"))
        sapply(data.files,
               function(x) {
                       if(!file.exists(x)) {
                               stop("File: \"", x, "\" doesn't exist. Stopping!\n")
                       }})
        
        return(data.files)
}

## "ProcessAndMergeData" function that receice a list of strings indicating the filenames
## and outputs the data frame with the tidy data
ProcessAndMergeData <- function(list.data.files) {
        if(is.null(list.data.files) || length(list.data.files) == 0) {
                stop("The list of data files to use for data processing is null/empty!\n")
        }
        activities <- read.table(list.data.files$activities, header=FALSE, col.names=c("id","name"))
        features <- read.table(list.data.files$features, header=FALSE,col.names=c("id","name"))
        features$name <- sapply(features$name, function(x) sub("^(t|f)","\\1\\.",x))
        features$name <- sapply(features$name, function(x) gsub("\\-|\\,",".",x))
        features$name <- sapply(features$name, function(x) gsub("\\(\\)","",x))
        features$name <- sapply(features$name, function(x) gsub("\\(",".",x))
        features$name <- sapply(features$name, function(x) gsub("\\)","",x))
        features$name <- sapply(features$name, function(x) gsub("([bB])ody[bB]ody","\\1ody",x))
        features$name <- sapply(features$name, function(x) tolower(x))
        subject.test  <- read.table(list.data.files$subject.test, header=FALSE, col.names=c("id"))
        subject.train <- read.table(list.data.files$subject.train, header=FALSE, col.names=c("id"))
        subjects <- rbind(subject.train, subject.test)
        data.test.x  <- read.table(list.data.files$xtest, header=FALSE, col.names=features$name)
        data.train.x <- read.table(list.data.files$xtrain, header=FALSE, col.names=features$name)
        data.x <- rbind(data.test.x, data.train.x)
        data.x <- data.x[,grep("\\.mean[^f]|\\.mean$|\\.std",features$name)]
        # Get activities results per subject (test and train)
        data.test.y  <- read.table(list.data.files$ytest, header=FALSE, col.names=c("activity"))
        data.train.y <- read.table(list.data.files$ytrain, header=FALSE, col.names=c("activity"))
        data.y <- rbind(data.test.y, data.train.y)
        data.y$activity <- activities[data.y$activity,]$name
        interm.dfrm <- cbind(subjects, data.x, data.y)
        # Calculate averages of data values per subject and activity
        result.dfrm <- aggregate(interm.dfrm[,grep("mean|std",names(interm.dfrm))], by=list(id=interm.dfrm$id,
                                         activity=interm.dfrm$activity), FUN ="mean")
        # Order  rows by subject
        result.dfrm <- result.dfrm[order(result.dfrm$id),]
        return(result.dfrm)      
}
## "WriteTidyDatasetCsv" function
WriteTidyDatasetCsv <- function (in.dfrm, out.csv.file=dataFileTidy, appendl=FALSE) {
        if(is.null(in.dfrm)) { 
                stop("The input data frame to function 'create.tidy.dataset' cannot be NULL!\n")
        }
        write.table(in.dfrm, out.csv.file, append=appendl, sep=",", row.names=FALSE, col.names=names(in.dfrm))
}

## Executing all functions in sequence to get the resulting CSV file
list.data.files=DetermineDataFiles()
dfrm=ProcessAndMergeData(list.data.files)
WriteTidyDatasetCsv(dfrm)