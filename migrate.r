library(connectapi)

# Connect to your "old" Posit Connect server
# Replace with your server URL and API key
connect <- connect(
  server = "https://pub.current.posit.team",
  api_key = "Pd3cJ3PUEEXNNC36pLyhNEgKSMlCsn4B"
)

# New Posit Connect Server
connect_new <- connect(
  server = "http://localhost:3939",
  api_key = "CfZMxt3iBqwDiDBeeoNAwYDP1enFlJTZ"
)

# Get all tag data
tag_data <- get_tag_data(connect)

# Extract the ID for the "Focused View" tag
my_tag <- tag_data[tag_data$name == "Focused View", ]
my_tag_id <- focused_view_tag$id

# Print the tag ID
cat("Selected tag ID:", my_tag_id, "\n")

# Get all content associated with the "Focused View" tag
relevant_content <- content_list_by_tag(connect, my_tag_id)

# # For testing purposes, I select content based on publisher
# users <- get_users(connect)
# my_guid <- users[users$username == "michael.mayer@posit.co", ]$guid

# relevant_content <- get_content(connect, owner_guid = my_guid)

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

# Get all bundle files in the current directory
bundle_files <- list.files(path = ".", pattern = "^bundle.*\\.tar\\.gz$", 
                           full.names = TRUE)

# Loop through each bundle file and deploy to the new server
for (bundle_file in bundle_files) {
  cat("Deploying bundle:", bundle_file, "\n")

  # Extract the content GUID from the bundle file name
  guid <- paste(strsplit(basename(bundle_file), "-")[[1]][2:6], collapse = "-")

  cat("GUID", guid, "\n")

  metadata <- relevant_content[relevant_content$guid == guid, ]

  # Create a bundle path object
  bundle <- bundle_path(bundle_file)

  deploy(connect_new, bundle, title = metadata$title, name = metadata$name)
  # Upload the bundle to the new server
  tryCatch({
    new_bundle_id <- deploy(connect_new, bundle, 
                            title = metadata$title, name = metadata$name)
    cat("Successfully deployed with bundle ID:", new_bundle_id, "\n\n")
  }, error = function(e) {
    cat("Error deploying bundle", bundle_file, ":", e$message, "\n\n")
  })
}