# New Posit Connect Server
connect_new <- connect(
  server = "http://localhost:3939",
  api_key = "HEpPwoynepeNtWduWUltC4B8Szyxm9t0"
)

# Get all bundle files in the current directory
bundle_files <- list.files(path = ".", pattern = "^bundle.*\\.tar\\.gz$", 
                           full.names = TRUE)

# Read CSV file 
relevant_content <- read.csv("relevant_content.csv")

# Loop through each bundle file and deploy to the new server
for (bundle_file in bundle_files) {
  cat("Deploying bundle:", bundle_file, "\n")

  # Extract the content GUID from the bundle file name
  guid <- paste(strsplit(basename(bundle_file), "-")[[1]][2:6], collapse = "-")

  cat("GUID:", guid, "\n")

  # Check if the GUID exists in relevant_content
  if (any(relevant_content$guid == guid)) {
    metadata <- relevant_content[relevant_content$guid == guid, ]
    
    # Create a bundle path object and ensure proper connection handling
    bundle <- NULL
    tryCatch({
      bundle <- bundle_path(bundle_file)
      
      # Print metadata safely
      cat("Metadata - Name:", as.character(metadata$name), "\n")
      cat("Metadata - Title:", as.character(metadata$title), "\n")
      
      # Upload the bundle to the new server
      new_bundle_id <- deploy(connect_new, bundle, 
                            title = as.character(metadata$title), 
                            name = as.character(metadata$name))
      cat("Successfully deployed with bundle ID:", new_bundle_id$content$guid, "\n\n")
    }, error = function(e) {
      cat("Error deploying bundle", bundle_file, ":", e$message, "\n\n")
    }, finally = {
      # Clean up any open connections
      if (!is.null(bundle) && inherits(bundle, "connection")) {
        tryCatch({
          close(bundle)
        }, error = function(e) {
          cat("Note: Could not close bundle connection:", e$message, "\n")
        })
      }
      
      # Force garbage collection to clean up any lingering connections
      gc()
    })
  } else {
    cat("Warning: No metadata found for GUID:", guid, "\n")
    cat("Skipping deployment for this bundle.\n\n")
  }

  # Modifying ownership of content
  content_owner <- metadata$owner
  cat("owner",content_owner, "\n")
  if (!is.na(content_owner)) {
    owner_guid <- user_guid_from_username(connect_new, content_owner)
    cat("owner guid",owner_guid, "\n")
    if (!is.na(owner_guid)) {
      content_update_owner(content_item(connect_new, new_bundle_id$content$guid), owner_guid)
    }
  }
}

# Final cleanup
gc()