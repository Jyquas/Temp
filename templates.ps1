# Connect to SharePoint Online
$siteUrl = "your_site_url"
$cred = Get-Credential
Connect-PnPOnline -Url $siteUrl -Credentials $cred

# Retrieve files from the Master Page Gallery
$files = Get-PnPListItem -List "Master Page Gallery" | Where-Object { $_["ContentType"] -like "*intranet*" }
# Connect to SharePoint Online
$siteUrl = "your_site_url"
$cred = Get-Credential
Connect-PnPOnline -Url $siteUrl -Credentials $cred

# Get the ID of the 'intranet' content type
$contentTypes = Get-PnPContentType
$intranetContentTypeId = $contentTypes | Where-Object { $_.Name -like "*intranet*" } | Select-Object -ExpandProperty Id
# Retrieve all files from the Master Page Gallery
$allFiles = Get-PnPListItem -List "Master Page Gallery" -Fields "ContentTypeId", "FileRef", "FileLeafRef"

# Filter files based on ContentType ID
$filteredFiles = $allFiles | Where-Object { $intranetContentTypeIds -contains $_["ContentTypeId"].StringValue }

# Process each filtered file
foreach ($file in $filteredFiles) {
    $fileUrl = $file.FieldValues.FileRef
    
    }
    # Disconnect the session
Disconnect-PnPOnline
