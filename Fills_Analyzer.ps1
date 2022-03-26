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
#>

param (
    [string]$csv = '.\fills.csv',
    [ValidateSet("grid", "table")]
    [string]$display = "table"
)

[System.Collections.ArrayList]$results = @()

# Load CSV rows into object array
$Fills = Import-Csv -Path "$importFile" 
$securities = $Fills."size unit" | Sort-Object | Get-Unique -AsString

foreach ($security in $securities) {
    [double]$expense = 0
    [double]$income = 0
    $quantSold = 0
    $quantPurchased = 0

    $securityData = $Fills | Where-Object { $_."size unit" -eq $security }
    $securitySell = $securityData | Where-Object { $_.side -eq "SELL" }
    $securityBuy = $securityData | Where-Object { $_.side -eq "BUY" }

    foreach ($row in $securitySell) {
        $income += ( [float]$row.size * [float]$row.price )
        $quantSold += [float]$row.size
    }
    foreach ($row in $securityBuy) {
        $expense += ( [float]$row.size * [float]$row.price )
        $quantPurchased += [float]$row.size
    }

    $results += [PSCustomObject]@{
        Security           = $security
        Average_Buy_Price  = ( $expense / $quantPurchased ).ToString("C3")
        Average_Sell_Price = ( $income / $quantSold ).ToString("C3")
        Income             = $income.ToString("C")
        Expense            = $expense.ToString("C")
        Profit             = ($income - $expense).ToString("C")
    }
}

switch ($display) {
    "grid" { $results | Out-GridView }
    "table" { $results | Format-Table -AutoSize }
}
