library(connectapi)

# Connect to your "old" Posit Connect server
# Replace with your server URL and API key
connect <- connect(
  server = "https://pub.current.posit.team",
  api_key = "Pd3cJ3PUEEXNNC36pLyhNEgKSMlCsn4B"
)

# Define tag to use for downloading bundles
my_tag <- "Focused View"

# Get all tag data
tag_data <- get_tag_data(connect)

# Extract the ID for the "Focused View" tag
my_tag <- tag_data[tag_data$name == my_tag, ]
my_tag_id <- my_tag$id

# Print the tag ID
cat("Selected tag ID:", my_tag_id, "\n")

# Get all content associated with the relevant tag
relevant_content <- content_list_by_tag(connect, my_tag_id)

# For testing purposes, I select content based on publisher
# users <- get_users(connect)
# my_guid <- users[users$username == "michael.mayer@posit.co", ]$guid

# relevant_content <- get_content(connect, owner_guid = my_guid)

selected_content <- relevant_content[, c("guid","name","title")]
# selected_content$owner <- "mm2"

# save data in csv file so that ownership can be added
write.csv(selected_content, file = "relevant_content.csv")

# If you want to see more details about each piece of content
for (guid in relevant_content$guid) {
  bundles <- get_bundles(content_item(connect, guid))
  bundle_count <- dim(bundles)[1]
  ctr <- 0
  for (bundle in bundles$id) {
    ctr <- ctr + 1
    filename <- paste0("bundle-", guid, "-", ctr, ".tar.gz")
    cat(paste0("Extracting guid ", guid , 
               " bundle ", ctr, "/", bundle_count, "\n"))
    download_bundle(
      content_item(connect, guid),
      filename = filename,
      bundle_id = bundle,
      overwrite = FALSE
    )
  }
}

