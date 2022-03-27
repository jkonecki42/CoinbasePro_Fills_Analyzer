<#
    CoinbasePro Fills Analyzer
    Analyzes Coinbase Fills report. 
    Displays results in PS Gridview or Console Table
    2022 Josh Konecki
#>

<#
    Parameters
    csv - specify the location of the CoinbasePro Fills report.
          Default is .\fills.csv
    display - grid or table. 
              grid opens up PS Gridview, table outputs to console window.
    beginDate/endDate "MM/DD/YYYY" - only processes fills after beginDate or before endDate.
#>

param (
    [string]$csv = '.\fills.csv',
    [ValidateSet("grid", "table", "none")]
    [string]$display = "table",
    [string]$outFile,
    [DateTime]$beginDate,
    [DateTime]$endDate
)
[System.Collections.ArrayList]$results = @()


# Load CSV rows into object array
$Fills = Import-Csv -Path "$importFile" 

if ($beginDate -ne $null) {
    $Fills = $Fills | Where-Object { [DateTime]$_."created at" -gt $beginDate }
}
if ($endDate -ne $null) {
    $Fills = $Fills | Where-Object { [Datetime]$_."created at" -lt $endDate }
}

$securities = $Fills."size unit" | Sort-Object | Get-Unique -AsString

foreach ($security in $securities) {
    $expense = 0
    $income = 0
    $quantSold = 0
    $quantBought = 0

    $securityData = $Fills | Where-Object { $_."size unit" -eq $security }
    $securitySell = $securityData | Where-Object { $_.side -eq "SELL" }
    $securityBuy = $securityData | Where-Object { $_.side -eq "BUY" }

    foreach ($row in $securitySell) {
        $income += ( [float]$row.size * [float]$row.price )
        $quantSold += [float]$row.size
    }
    foreach ($row in $securityBuy) {
        $expense += ( [float]$row.size * [float]$row.price )
        $quantBought += [float]$row.size
    }

    if ($quantSold -eq 0) { $averageSellPrice = "None Sold" }
    else { $averageSellPrice = ( $income / $quantSold ).ToString("C3") }

    if ($quantBought -eq 0) { $averageBuyPrice = "None Bought" }
    else { $averageBuyPrice = ( $expense / $quantBought ).ToString("C3") }
    
    $results += [PSCustomObject]@{
        Security           = $security
        Average_Buy_Price  = $averageBuyPrice
        Average_Sell_Price = $averageSellPrice
        Income             = $income.ToString("C")
        Expense            = $expense.ToString("C")
        Profit             = ($income - $expense).ToString("C")
    }
}

switch ($display) {
    "grid" { $results | Out-GridView -Title "CBPro Fills Data" }
    "table" { $results | Format-Table -AutoSize }
    "none" { "Skipping display." }
}

if ($outFile) {
    $results | Export-Csv -NoTypeInformation -Path "$outFile"
    if ($?) { Write-Output "${outFile} Successfully created." }
    else { Write-Output "Failed to create $outFile." }
}
