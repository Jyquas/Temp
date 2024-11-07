# Define the path to the .dat file
$filePath = "C:\path\to\your\file.dat"

# Define the field specifications with Length and Type for each of the first 40 fields
$fieldSpecifications = @(
    @{ Length = 3; Type = 'Character' },
    @{ Length = 4; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 4; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 2; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 2; Type = 'Character' },
    @{ Length = 4; Type = 'Character' },
    @{ Length = 4; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 5; Type = 'Character' },
    @{ Length = 7; Type = 'Character' },
    @{ Length = 2; Type = 'Number' },      # Numeric field
    @{ Length = 39; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 4; Type = 'Number' },      # Numeric field
    @{ Length = 6; Type = 'Number' },      # Numeric field
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 1; Type = 'Character' },
    @{ Length = 2; Type = 'Character' },
    @{ Length = 3; Type = 'Character' },
    @{ Length = 2; Type = 'Character' },
    @{ Length = 8; Type = 'Date' },        # Date as character field
    @{ Length = 8; Type = 'Date' }         # Date as character field
)

# Open the file stream and binary reader
$stream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
$reader = [System.IO.BinaryReader]::new($stream)

# Initialize an array to hold the data
$data = @()

try {
    # Loop through each field specification
    foreach ($fieldSpec in $fieldSpecifications) {
        $length = $fieldSpec.Length
        $type = if ($fieldSpec.ContainsKey("Type")) { $fieldSpec.Type } else { 'Character' }
        $bytes = $reader.ReadBytes($length)

        # Process data based on specified type
        switch ($type) {
            'Character' {
                # Treat as ASCII string, trimming any null characters if needed
                $value = [System.Text.Encoding]::ASCII.GetString($bytes).TrimEnd([char]0)
            }
            'Number' {
                # Convert numeric fields based on length (adjust as needed for type)
                if ($length -le 2) {
                    $value = [BitConverter]::ToInt16($bytes, 0)      # Short integer for 2 bytes
                } elseif ($length -le 4) {
                    $value = [BitConverter]::ToInt32($bytes, 0)      # Integer for 4 bytes
                } elseif ($length -le 8) {
                    $value = [BitConverter]::ToInt64($bytes, 0)      # Long integer for larger lengths
                }
            }
            'Date' {
                # Date as 8-character string (e.g., YYYYMMDD format)
                $value = [System.Text.Encoding]::ASCII.GetString($bytes).TrimEnd([char]0)
                # Optional: Convert to date object if needed
                if ($value -match '^\d{8}$') {
                    $year = [int]$value.Substring(0, 4)
                    $month = [int]$value.Substring(4, 2)
                    $day = [int]$value.Substring(6, 2)
                    $value = [datetime]::new($year, $month, $day)
                }
            }
            Default {
                # Fallback to Character if no specific type matched
                $value = [System.Text.Encoding]::ASCII.GetString($bytes).TrimEnd([char]0)
            }
        }

        # Add the value to data array
        $data += $value
    }

    # Output the data
    $data | ForEach-Object { Write-Output $_ }
}
catch {
    Write-Error "An error occurred while processing the file: $_"
}
finally {
    # Clean up
    $reader.Close()
    $stream.Close()
}
