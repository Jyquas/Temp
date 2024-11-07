# Set the directory paths
$sharedPath = "C:\path\to\shared\directory"   # Path to the shared directory with .dat files
$archivePath = "$sharedPath\archive"          # Path to archive processed files

# Ensure the archive directory exists
if (!(Test-Path -Path $archivePath)) {
    New-Item -ItemType Directory -Path $archivePath
}

# Define byte lengths for each field (only define up to field 40)
$fieldByteLengths = @(3, 4, 6, 8, 2, 3, 4, 3, 5, 6, 2, 4, 3, 3, 2, 4, 6, 4, 3, 2, 
                     5, 3, 2, 4, 3, 6, 2, 5, 4, 6, 3, 2, 5, 4, 3, 2, 6, 3, 4, 2)

# Define a helper function to read specific bytes and convert to types
function Read-FieldData ($reader, $length) {
    $bytes = $reader.ReadBytes($length)

    # Convert based on the length (assuming most fields are integer or string in this case)
    if ($length -eq 4) {
        return [BitConverter]::ToInt32($bytes, 0)  # Convert 4-byte integer
    } elseif ($length -eq 8) {
        return [BitConverter]::ToDouble($bytes, 0)  # Convert 8-byte double
    } else {
        return [System.Text.Encoding]::ASCII.GetString($bytes).Trim()  # Convert to string
    }
}

# Process each .dat file in the shared directory
Get-ChildItem -Path $sharedPath -Filter "*.dat" | ForEach-Object {
    $filePath = $_.FullName
    Write-Output "Processing file: $filePath"

    # Open the file for binary reading
    $fileStream = [System.IO.File]::OpenRead($filePath)
    $reader = New-Object System.IO.BinaryReader($fileStream)

    try {
        # Read data from the first 40 fields
        $dataRecord = @{}
        for ($i = 0; $i -lt 40; $i++) {
            $dataRecord["Field$($i + 1)"] = Read-FieldData -reader $fieldByteLengths[$i]
        }

        # Output or process data as needed
        Write-Output "Data Record:"
        $dataRecord.GetEnumerator() | ForEach-Object { Write-Output "$($_.Key): $($_.Value)" }

        # Close and archive the file after processing
        $reader.Close()
        $fileStream.Close()
        Move-Item -Path $filePath -Destination "$archivePath\$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($_.Name)"
    }
    catch {
        Write-Output "Error processing file: $_"
    }
    finally {
        # Ensure resources are closed
        if ($reader) { $reader.Close() }
        if ($fileStream) { $fileStream.Close() }
    }
}
