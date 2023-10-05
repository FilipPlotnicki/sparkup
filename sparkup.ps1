# Invoke-Expression ([System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri http://localhost:8000/test.ps1 -UseBasicParsing).Content))

# Versions
$sparkVersion = "3.5.0"
$hadoopVersion = "3"

# Determine user's home directory
$homeDir = $env:USERPROFILE

# Download Spark
$sparkRootDir = Join-Path -Path $homeDir -ChildPath "spark"
$sparkCacheDir = Join-Path -Path $sparkRootDir -ChildPath ".cache"
$sparkDir = Join-Path -Path $sparkRootDir -ChildPath "spark-$sparkVersion-bin-hadoop$hadoopVersion"
$sparkBinDir = Join-Path -Path $sparkDir -ChildPath $sparkBinDir

if (-not (Test-Path $sparkRootDir -PathType Container)) {
    New-Item -ItemType Directory -Path $sparkRootDir
}

if (-not (Test-Path $sparkCacheDir -PathType Container)) {
    New-Item -ItemType Directory -Path $sparkCacheDir
}

$sparkPackageURL = "https://downloads.apache.org/spark/spark-$sparkVersion/spark-$sparkVersion-bin-hadoop$hadoopVersion.tgz" 
$sparkPackageLocation = Join-Path -Path $sparkCacheDir -ChildPath "spark-$sparkVersion.tgz"

# Download spark package
if (-not (Test-Path $sparkPackageLocation -PathType Leaf)) {
    Write-Host "Downloading Apache Spark $sparkVersion-hadoop$hadoopVersion to $sparkPackageLocation..."
    Invoke-WebRequest -Uri $sparkPackageURL -OutFile $sparkPackageLocation
} else {
    Write-Host "Apache Spark in version $sparkVersion-hadoop$hadoopVersion was already downloaded to $sparkPackageLocation"
}

# Extract spark
if (-not (Test-Path $sparkDir -PathType Container)) {
    Write-Host "Extracting Apache Spark to $sparkDir..."
    tar -xf $sparkPackageLocation -C $sparkRootDir
} else {
    Write-Host "Apache Spark in version $sparkVersion-hadoop$hadoopVersion was already extracted to $sparkDir"
}


# Setup PySpark
$pysparkPath = "$sparkDir\python\lib\pyspark.zip"
$py4jPath = "$sparkDir\python\lib\py4j-*\py4j.zip"

# Add PySpark and Py4J to PYTHONPATH
$pythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
$pathsToAdd = @($pysparkPath, $py4jPath)
$isUpdateNeeded = $false

foreach ($path in $pathsToAdd) {
    if (-not ($pythonPath -like "*$path*")) {
        $pythonPath = "$path;" + $pythonPath
        $isUpdateNeeded = $true
    }
}

if ($isUpdateNeeded) {
    [Environment]::SetEnvironmentVariable("PYTHONPATH", $pythonPath, "User")
    Write-Host "PYTHONPATH has been updated to include PySpark and Py4J."
} else {
    Write-Host "PYTHONPATH already includes PySpark and Py4J."
}

# Set SPARK_HOME
[Environment]::SetEnvironmentVariable("SPARK_HOME", $sparkDir, "User")
Write-Host "SPARK_HOME environment variable has been set to $sparkDir."

# Setup Hadoop for Windows
# Check for existing hadoop config
if (-not ([Environment]::GetEnvironmentVariable("HADOOP_HOME", "User"))) {
    $hadoopHome = $sparkDir
    $hadoopBinDir = $sparkBinDir

    # Download winutils.exe
    if (-not (Test-Path "$hadoopBinDir\winutils.exe" -PathType Leaf)) {
        $winutilsURL = "https://github.com/steveloughran/winutils/blob/master/hadoop-3.0.0/bin/winutils.exe"
        Invoke-WebRequest -Uri $winutilsURL -OutFile "$hadoopBinDir\winutils.exe"
        Write-Host "winutils.exe for Hadoop 3 has been downloaded and placed in $hadoopBinDir."
    } else {
        Write-Host "winutils.exe already exists in $hadoopBinDir."
    }

    [Environment]::SetEnvironmentVariable("HADOOP_HOME", $hadoopHome, "User")
    Write-Host "HADOOP_HOME environment variable has been set to $hadoopHome."
} else {
    Write-Host "HADOOP_HOME environment variable already exists and is set to: " + [Environment]::GetEnvironmentVariable("HADOOP_HOME", "User")
}

Write-Host "Apache Spark has been installed to $sparkDir"
