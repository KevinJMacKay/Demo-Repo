# Path to the log file
$FilePath = "C:\Users\kmackay\Downloads\postgresql.log.2024-12-17-1400"

# Read the log file
$Log = Get-Content -Path $FilePath

# Regular expressions to match the table name and the error message
$tablePattern = 'COPY\s+"[^"]+"\."([^"]+)"'
$errorPattern = 'ERROR:\s+(.*)'

# Initialize variables to store the current error and table name
$currentError = ""
$currentTable = ""

# Loop through each line and search for the patterns
foreach ($line in $Log) {
    if ($line -match $errorPattern) {
        $currentError = $matches[1]
    }
    if ($line -match $tablePattern) {
        $currentTable = $matches[1]
        Write-Output "Table name: $currentTable"
        Write-Output "Error: $currentError"
        # Reset the current error after outputting
        $currentError = ""
    }
}

# Define the path to the log file
$logFilePath = "C:\Users\kmackay\Downloads\postgresql.log.2024-12-17-1400"
$logFilePath_new = "C:\Users\kmackay\Downloads\postgresql.log.2024-12-17-1400_new"

# Read the log lines from the file
$logLines = Get-Content -Path $logFilePath

# Filter out lines containing "skipping missing configuration"
$filteredLines = $logLines | Where-Object { $_ -notmatch ":LOG:" }
$filteredLines = $filteredLines | Where-Object { $_ -notmatch ":DETAIL:" }

# Write the filtered lines back to the file
$filteredLines | Set-Content -Path $logFilePath_new

#----------------------------------------------------------------------------------------------------------------------------

# Define the path to the log file
$logFilePath = "C:\Users\kmackay\Downloads\postgresql.log.2024-12-23-1300"
$logFilePath_new = $logFilePath_new.Replace(".log", "_new.log")

# Create the new file
New-Item -Path $logFilePath_new -ItemType File -Force


# Read the log lines from the file
$logLines = Get-Content -Path $logFilePath

# Filter out lines containing "skipping missing configuration"
$filteredLines = $logLines | Where-Object { $_ -notmatch ":LOG:" }
$filteredLines = $filteredLines | Where-Object { $_ -notmatch ":DETAIL:" }

# Remove the date stamp and store the rest of the line
$linesWithoutDate = $filteredLines | ForEach-Object { $_ -replace '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC:[^:]+:', '' }

# Remove duplicate lines and count the total number of duplicates
$uniqueLines = $linesWithoutDate | Sort-Object -Unique
$totalDuplicates = $linesWithoutDate.Count - $uniqueLines.Count

# Write the unique lines back to the new file
$uniqueLines | Set-Content -Path $logFilePath_new

# Output the total number of duplicates removed
Write-Output "Total duplicates removed: $totalDuplicates"

# Open the new file
Start-Process code -ArgumentList $logFilePath_new