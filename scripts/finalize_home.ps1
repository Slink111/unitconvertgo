$unitsJson = Get-Content -Path "data\units.json" -Raw | ConvertFrom-Json
$contentJson = Get-Content -Path "data\content.json" -Raw | ConvertFrom-Json

$baseTemp = Get-Content -Path "templates\base.html" -Raw
$homeTemp = Get-Content -Path "templates\home.html" -Raw

$toolsIndex = @()
foreach ($catId in (Get-ChildItem -Path "public" -Directory).Name) {
    if ($catId -eq "css" -or $catId -eq "js") { continue }
    foreach ($file in (Get-ChildItem -Path "public\$catId" -Filter "*.html")) {
        $toolsIndex += @{
            "title" = $file.BaseName.Replace("-", " ")
            "url" = "/$catId/$($file.Name)"
            "category" = $catId
            "keywords" = @($file.BaseName.Replace("-to-", " "))
        }
    }
}

$categoryGrid = ""
foreach ($cat in $unitsJson.categories) {
    $categoryGrid += "
        <a href='/$($cat.slug).html' class='glass p-8 rounded-3xl border border-blue-50 card-hover text-center block'>
            <div class='w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center text-blue-600 mx-auto mb-4 font-bold text-xl'>$($cat.name.Substring(0,1))</div>
            <h3 class='font-bold text-gray-900 mb-1'>$($cat.name)</h3>
            <p class='text-xs text-gray-400 uppercase tracking-widest'>$($cat.units.Count) Units</p>
        </a>"
}

$popularTools = ""
$topTools = @("kilogram-to-pound", "meter-to-foot", "acre-to-square-feet", "celsius-to-fahrenheit")
foreach ($slug in $topTools) {
    # Find matching tool in index
    foreach($t in $toolsIndex) {
        if ($t.url -like "*$slug*") {
            $popularTools += "
            <a href='$($t.url)' class='bg-white p-6 rounded-2xl border border-gray-100 card-hover flex items-center justify-between group'>
                <div>
                    <h3 class='font-bold text-gray-900 group-hover:text-blue-600 transition-colors'>$($t.title)</h3>
                    <p class='text-sm text-gray-400'>$($t.category)</p>
                </div>
                <svg class='w-5 h-5 text-gray-300 group-hover:text-blue-600 transition-colors' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M9 5l7 7-7 7'></path></svg>
            </a>"
            break
        }
    }
}

$homeContent = $homeTemp.Replace("{{categoryGrid}}", $categoryGrid).Replace("{{popularTools}}", $popularTools).Replace("{{toolsIndex}}", ($toolsIndex | ConvertTo-Json -Compress))
$finalHomeHtml = $baseTemp.Replace("{{title}}", "UnitConvert.io - Fast & Accurate").Replace("{{metaDescription}}", "Universal unit converter.").Replace("{{content}}", $homeContent).Replace("{{canonicalUrl}}", "https://unitconvert.io/").Replace("{{additionalHead}}", "")

Set-Content -Path "public\index.html" -Value $finalHomeHtml
Write-Host "Homepage Finalized."
