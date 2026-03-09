$unitsJson = Get-Content -Path "data\units.json" -Raw | ConvertFrom-Json
$contentJson = Get-Content -Path "data\content.json" -Raw | ConvertFrom-Json
$modularJson = Get-Content -Path "data\modular_content.json" -Raw | ConvertFrom-Json

$baseTemp = Get-Content -Path "templates\base.html" -Raw
$homeTemp = Get-Content -Path "templates\home.html" -Raw
$catTemp = Get-Content -Path "templates\category.html" -Raw
$convTemp = Get-Content -Path "templates\converter.html" -Raw

$toolsIndex = @()

function Render-Template($template, $data) {
    $result = $template
    foreach ($key in $data.Keys) {
        $placeholder = "{{$key}}"
        $result = $result.Replace($placeholder, [string]$data[$key])
    }
    return $result
}

function Get-JsonLd($faqs) {
    if ($faqs.Count -eq 0) { return "" }
    $items = @()
    foreach ($faq in $faqs) {
        $items += "{
            ""@type"": ""Question"",
            ""name"": ""$($faq.q)"",
            ""acceptedAnswer"": {
                ""@type"": ""Answer"",
                ""text"": ""$($faq.a)""
            }
        }"
    }
    $json = $items -join ","
    return "<script type='application/ld+json'>
    {
      ""@context"": ""https://schema.org"",
      ""@type"": ""FAQPage"",
      ""mainEntity"": [$json]
    }
    </script>"
}

# Create directories
$dirs = @("", "length", "area", "weight", "volume", "temperature", "speed", "time", "storage", "energy")
foreach ($d in $dirs) {
    $p = Join-Path "public" $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p }
}

Write-Host "Starting Massive SEO Generation (1700+ words per page)..."

foreach ($cat in $unitsJson.categories) {
    Write-Host "Processing Category: $($cat.name)"
    
    $catSlug = $cat.slug
    $catId = $cat.id
    $catToolLinks = @()
    
    # Category specific modular content
    $catModular = if ($modularJson.categories."$catId") { $modularJson.categories."$catId" } else { "Understanding $($cat.name) units is critical for professional and personal accuracy." }
    
    foreach ($from in $cat.units) {
        foreach ($to in $cat.units) {
            if ($from.id -eq $to.id) { continue }
            
            $slug = "$($from.id)-to-$($to.id)"
            $filename = "$catId/$slug.html"
            $url = "/$filename"
            
            # Check for predefined content
            $predefined = $contentJson.tools."$slug"
            if (-not $predefined) { $predefined = $contentJson.tools."$($from.name)-to-$($to.name)" } # fallback
            
            $title = if ($predefined.title) { $predefined.title } else { "$($from.name) to $($to.name) Converter - Convert $($from.name) to $($to.name) Instantly" }
            $metaDesc = if ($predefined.metaDescription) { $predefined.metaDescription } else { "Quick and accurate conversion from $($from.name) to $($to.name). Learn the formula, see examples, and convert instantly." }
            
            $isTemp = $cat.id -eq "temperature"
            $actualFactor = 1.0
            $formula = ""
            $howTo = ""
            
            if ($isTemp) {
                if ($from.id -eq "c" -and $to.id -eq "f") { $formula = "°F = (°C × 9/5) + 32" }
                elseif ($from.id -eq "f" -and $to.id -eq "c") { $formula = "°C = (°F - 32) × 5/9" }
                elseif ($from.id -eq "c" -and $to.id -eq "k") { $formula = "K = °C + 273.15" }
                elseif ($from.id -eq "k" -and $to.id -eq "c") { $formula = "°C = K - 273.15" }
                
                $howTo = "Converting $($from.name) to $($to.name) involves using a specific temperature scale formula. Use our tool for an instant and accurate calculation."
                $exampleRows = "<tr><td class='px-6 py-4'>0 °$($from.id.ToUpper())</td><td class='px-6 py-4'>---</td></tr>"
            } else {
                $actualFactor = [double]$from.factor / [double]$to.factor
                $formula = "1 $($from.name) = $($actualFactor.ToString("F6").TrimEnd('0').TrimEnd('.')) $($to.name)s"
                $howTo = "To convert $($from.name)s to $($to.name)s, multiply the value by $($actualFactor.ToString("F6").TrimEnd('0').TrimEnd('.')). Our online tool makes this calculation instant and error-free."
                
                $exampleRows = ""
                foreach ($val in @(1, 5, 10, 20, 50, 100)) {
                    $res = $val * $actualFactor
                    $exampleRows += "<tr><td class='px-6 py-4'>$val $($from.id)</td><td class='px-6 py-4'>$($res.ToString("F4").TrimEnd('0').TrimEnd('.')) $($to.id)</td></tr>"
                }
            }

            # FAQs
            $faqs = if ($predefined.faqs) { $predefined.faqs } else {
                @(
                    @{ "q" = "How many $($to.name)s are in one $($from.name)?"; "a" = "There are exactly $($actualFactor.ToString("F6").TrimEnd('0').TrimEnd('.')) $($to.name)s in one $($from.name)." },
                    @{ "q" = "What is the formula to convert $($from.id) to $($to.id)?"; "a" = "To convert $($from.name) to $($to.name), multiply the value by $($actualFactor.ToString("F6").TrimEnd('0').TrimEnd('.'))." }
                )
            }

            # STITCH LONG-FORM BLOG (1700+ words)
            $toolBlog = if ($predefined.blog) { $predefined.blog } else {
                "The conversion between $($from.name) and $($to.name) is a fundamental part of $($cat.name.ToLower()) calculations. Whether you're working on a professional project or just need a quick answer for a daily task, understanding how to move between these units is essential. The relational value between $($from.name) and $($to.name) is defined by the standard conversion factor of $($actualFactor.ToString("F6").TrimEnd('0').TrimEnd('.')). For those who prefer a manual calculation, simply multiply your input by this factor. However, for speed and precision, using a dedicated online converter like ours is the most efficient way to ensure your results are error-free and instant."
            }

            # Dynamic "Practical Industry Deep Dive" section (specific to the tool)
            $industrySection = "<h3>The Significance of $($from.id.ToUpper()) to $($to.id.ToUpper()) in Modern Industry</h3><p>Beyond simple everyday lookups, the transition from $($from.name) to $($to.name) plays a critical role in sectors such as international logistics, architectural design, and scientific research. For instance, in shipping, the accuracy of weight or volume conversion directly impacts fuel consumption estimates and safety protocols. In construction, failing to distinguish between different measurement standards can lead to costly material wastage and project delays. Our tool is optimized to provide the exactness required for these high-stakes calculations, ensuring that your data remains robust regardless of where in the world your project is located. We use high-precision floating-point arithmetic to maintain fidelity even with extremely large or small values, making this a reliable resource for researchers and students alike.</p>"

            # Stitch all modules
            $fullBlog = @"
                <div class='seo-long-blog'>
                    <div class='tool-intent mb-10'>
                        $toolBlog
                    </div>
                    
                    <div class='modular-sections space-y-12 text-gray-700 leading-relaxed text-lg'>
                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>Technical Specifications and Formula</h2>
                            <p>$howTo</p>
                            <p class='mt-4 font-semibold text-blue-800'>The mathematical formula is: value_in_$($to.id) = value_in_$($from.id) × $($actualFactor.ToString("F8").TrimEnd('0').TrimEnd('.'))</p>
                        </div>

                        $industrySection

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>A Deep Dive into $($cat.name) Units</h2>
                            <p>$catModular</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>The Historical Evolution of Global Measurement Standards</h2>
                            <p>$($modularJson.universal.history_of_standards)</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>Metric vs Imperial: The Infinite Global Divide</h2>
                            <p>$($modularJson.universal.metric_vs_imperial)</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>Precision in the 21st Century: Why Metrology Matters</h2>
                            <p>$($modularJson.universal.precision_in_tech)</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>Common Conversion Pitfalls and How to Avoid Them</h2>
                            <p>$($modularJson.common_errors)</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>The Future of Measurement: From Objects to Constants</h2>
                            <p>$($modularJson.universal.future_of_measurement)</p>
                        </div>

                        <div class='modular-block'>
                            <h2 class='text-2xl font-bold text-gray-900 mb-4'>The Economic Impact of Accurate Metrology</h2>
                            <p>$($modularJson.universal.metrology_impact)</p>
                        </div>
                    </div>
                </div>
"@

            $faqHtml = ""
            foreach ($f in $faqs) {
                $faqHtml += "<div class='bg-gray-50 p-6 rounded-2xl border border-gray-100'><h3 class='font-bold text-gray-900 mb-2'>$($f.q)</h3><p class='text-gray-600'>$($f.a)</p></div>"
            }

            # Generate Unit Options for dropdowns
            $unitOptions = ""
            foreach ($u in $cat.units) {
                $unitOptions += "<option value='$($u.id)'>$($u.name) ($($u.id))</option>"
            }

            $toolData = @{
                "title" = $title
                "metaDescription" = $metaDesc
                "h1" = if ($predefined.h1) { $predefined.h1 } else { "$($from.name) to $($to.name) Converter" }
                "blog" = $fullBlog
                "fromUnitName" = $from.name
                "fromUnitPlural" = "$($from.name)s"
                "fromUnitShort" = $from.id
                "fromUnitId" = $from.id
                "toUnitName" = $to.name
                "toUnitPlural" = "$($to.name)s"
                "toUnitShort" = $to.id
                "toUnitId" = $to.id
                "factor" = $actualFactor
                "formula" = $formula
                "howTo" = "Our online converter provides a fast and reliable way to translate $($from.name)s into $($to.name)s using the standard conversion factor. Simply enter your value and watch the results update in real-time."
                "canonicalUrl" = "https://unitconvert.io$url"
                "exampleTableRows" = $exampleRows
                "faqs" = $faqHtml
                "relatedConverters" = "<a href='/$catSlug.html' class='p-4 bg-gray-50 rounded-xl hover:bg-blue-50 border border-gray-100 transition-colors font-medium text-blue-600'>Back to $($cat.name) Converters</a>"
                "jsonLdSchema" = Get-JsonLd $faqs
                "additionalHead" = ""
                "categoryId" = $cat.id
                "categoryName" = $cat.name
                "categorySlug" = $catSlug
                "toolShortTitle" = "$($from.id.ToUpper()) to $($to.id.ToUpper())"
                "unitOptions" = $unitOptions
                "unitsJson" = ($cat.units | ConvertTo-Json -Compress)
            }

            $content = Render-Template $convTemp $toolData
            $finalHtml = Render-Template $baseTemp @{
                "title" = $toolData.title
                "metaDescription" = $toolData.metaDescription
                "content" = $content
                "canonicalUrl" = $toolData.canonicalUrl
                "additionalHead" = ""
                "jsonLdSchema" = $toolData.jsonLdSchema
            }

            Set-Content -Path (Join-Path "public" $filename) -Value $finalHtml
            
            $toolsIndex += @{
                "title" = "$($from.name) to $($to.name)"
                "url" = $url
                "category" = $cat.name
                "keywords" = @($from.name, $to.name, "$($from.id) to $($to.id)", "how many $($to.id) in $($from.id)")
            }
            $catToolLinks += "<a href='$url' class='p-4 bg-gray-50 rounded-xl hover:bg-blue-50 border border-gray-100 transition-colors font-medium text-gray-700'>$($from.name) to $($to.name)</a>"
        }
    }

    # Generate Category Page
    $catTitle = if ($contentJson.categories."$catId".title) { $contentJson.categories."$catId".title } else { "$($cat.name) Converters" }
    $catDesc = if ($contentJson.categories."$catId".description) { $contentJson.categories."$catId".description } else { "Fast and accurate conversion tools for $($cat.name)." }
    $catSeo = if ($contentJson.categories."$catId".seoContent) { $contentJson.categories."$catId".seoContent } else { "Browse our collection of $($cat.name) converters." }
    
    $catContent = @{
        "categoryName" = $cat.name
        "title" = $catTitle
        "description" = $catDesc
        "seoContent" = $catSeo
        "toolLinks" = ($catToolLinks -join "`n")
    }
    $catPageContent = Render-Template $catTemp $catContent
    $finalCatHtml = Render-Template $baseTemp @{
        "title" = $catContent.title
        "metaDescription" = $catContent.description
        "content" = $catPageContent
        "canonicalUrl" = "https://unitconvert.io/$($catSlug).html"
        "additionalHead" = ""
        "jsonLdSchema" = ""
    }
    Set-Content -Path (Join-Path "public" "$catSlug.html") -Value $finalCatHtml
}

# Generate Category Grid Tiles
$catGridHtml = ""
foreach ($cat in $unitsJson.categories) {
    $icon = "&#128207;" # Ruler
    $bgClass = "bg-blue-50"
    $borderClass = "border-blue-100"
    $iconBg = "bg-blue-100"
    $textColor = "text-blue-600"

    if ($cat.id -eq "area") { 
        $icon = "&#128506;"; $bgClass = "bg-emerald-50"; $borderClass = "border-emerald-100"; $iconBg = "bg-emerald-100"; $textColor = "text-emerald-600" 
    }
    elseif ($cat.id -eq "weight") { 
        $icon = "&#9878;"; $bgClass = "bg-purple-50"; $borderClass = "border-purple-100"; $iconBg = "bg-purple-100"; $textColor = "text-purple-600" 
    }
    elseif ($cat.id -eq "volume") { 
        $icon = "&#129514;"; $bgClass = "bg-indigo-50"; $borderClass = "border-indigo-100"; $iconBg = "bg-indigo-100"; $textColor = "text-indigo-600" 
    }
    elseif ($cat.id -eq "temperature") { 
        $icon = "&#127777;"; $bgClass = "bg-red-50"; $borderClass = "border-red-100"; $iconBg = "bg-red-100"; $textColor = "text-red-600" 
    }
    elseif ($cat.id -eq "speed") { 
        $icon = "&#128640;"; $bgClass = "bg-orange-50"; $borderClass = "border-orange-100"; $iconBg = "bg-orange-100"; $textColor = "text-orange-600" 
    }
    elseif ($cat.id -eq "time") { 
        $icon = "&#128344;"; $bgClass = "bg-teal-50"; $borderClass = "border-teal-100"; $iconBg = "bg-teal-100"; $textColor = "text-teal-600" 
    }
    elseif ($cat.id -eq "storage") { 
        $icon = "&#128190;"; $bgClass = "bg-cyan-50"; $borderClass = "border-cyan-100"; $iconBg = "bg-cyan-100"; $textColor = "text-cyan-600" 
    }
    elseif ($cat.id -eq "energy") { 
        $icon = "&#9889;"; $bgClass = "bg-amber-50"; $borderClass = "border-amber-100"; $iconBg = "bg-amber-100"; $textColor = "text-amber-600" 
    }
    
    $catGridHtml += @"
        <a href="/$($cat.slug).html" class="$bgClass p-8 rounded-3xl border $borderClass hover:scale-105 transition-all group block shadow-sm hover:shadow-md">
            <div class="w-16 h-16 $iconBg rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:scale-110 transition-transform shadow-inner">
                $icon
            </div>
            <h3 class="text-xl font-bold text-gray-900 brand-font mb-2">$($cat.name)</h3>
            <p class="text-gray-500 text-sm leading-relaxed">Fast and precise conversion between $($cat.units.Count) different units.</p>
            <div class="mt-4 flex items-center $textColor font-bold text-sm">
                <span>Explore Tools</span>
                <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
            </div>
        </a>
"@
}

# Generate Popular Tools Tiles
$popularToolsList = @(
    @{ "slug" = "kg-to-pound"; "cat" = "weight"; "title" = "Kg to Pound" },
    @{ "slug" = "meter-to-foot"; "cat" = "length"; "title" = "Meter to Foot" },
    @{ "slug" = "acre-to-sqft"; "cat" = "area"; "title" = "Acre to Square Feet" },
    @{ "slug" = "mb-to-gb"; "cat" = "storage"; "title" = "MB to GB" }
)

$popularHtml = ""
foreach ($tool in $popularToolsList) {
    $toolUrl = "/$($tool.cat)/$($tool.slug).html"
    $popularHtml += @"
        <a href="$toolUrl" class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all flex items-center justify-between group block">
            <div>
                <h3 class="font-bold text-gray-900">$($tool.title)</h3>
                <span class="text-xs text-gray-400 uppercase tracking-widest">$($tool.cat)</span>
            </div>
            <div class="text-blue-600 group-hover:translate-x-1 transition-transform">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
            </div>
        </a>
"@
}

# Generate Homepage
$homeRendered = Render-Template $homeTemp @{
    "categoryGrid" = $catGridHtml
    "popularTools" = $popularHtml
    "toolsIndex" = ($toolsIndex | ConvertTo-Json -Compress)
    "blogTitle" = $contentJson.home.blogTitle
    "blogContent" = $contentJson.home.blogContent
    "faqs" = "Home FAQs"
}

# Simple finalize_home logic integrated
$finalHomeHtml = Render-Template $baseTemp @{
    "title" = "UnitConvert.io - Fast & Accurate Unit Converters"
    "metaDescription" = $contentJson.general.description
    "content" = $homeRendered
    "canonicalUrl" = "https://unitconvert.io/"
    "additionalHead" = ""
    "jsonLdSchema" = Get-JsonLd $contentJson.home.faqs
}
Set-Content -Path "public\index.html" -Value $finalHomeHtml

Write-Host "Generated $($toolsIndex.Count) SEO-enhanced tools with 1700+ word blogs."
