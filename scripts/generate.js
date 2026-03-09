const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../data');
const TEMPLATES_DIR = path.join(__dirname, '../templates');
const OUTPUT_DIR = path.join(__dirname, '../public');

// Ensure output directories exist
const dirs = ['', 'length', 'area', 'weight', 'volume', 'temperature', 'speed', 'time', 'storage', 'energy'];
dirs.forEach(d => {
    const p = path.join(OUTPUT_DIR, d);
    if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
});

const unitsData = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'units.json'), 'utf8'));
const contentData = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'content.json'), 'utf8'));

const baseTemp = fs.readFileSync(path.join(TEMPLATES_DIR, 'base.html'), 'utf8');
const homeTemp = fs.readFileSync(path.join(TEMPLATES_DIR, 'home.html'), 'utf8');
const catTemp = fs.readFileSync(path.join(TEMPLATES_DIR, 'category.html'), 'utf8');
const convTemp = fs.readFileSync(path.join(TEMPLATES_DIR, 'converter.html'), 'utf8');

const toolsIndex = [];

function render(template, data) {
    return template.replace(/\{\{(\w+)\}\}/g, (match, key) => data[key] || '');
}

function generateSite() {
    console.log('Generating Unit Converter Website...');

    // 1. Generate Converter Pages
    unitsData.categories.forEach(cat => {
        const catContent = contentData.categories[cat.id] || { title: cat.name, description: `Tools for ${cat.name} conversion.` };
        
        for (let i = 0; i < cat.units.length; i++) {
            for (let j = 0; j < cat.units.length; j++) {
                if (i === j) continue;
                
                // Limit generation to most relevant ones to avoid bloat for now, 
                // but aim for the 50-100 requested.
                // We'll generate at least the first few pairs for each category.
                const from = cat.units[i];
                const to = cat.units[j];
                
                // Filter: we want specific pairs mentioned in the prompt or useful ones.
                // For this project, let's generate all pairs within a category if manageable.
                // Total units per category avg ~10, so 90 pairs per category. 9 categories * 90 = 810 pages.
                // This fits "scale from 100 to 1000".
                
                const slug = `${from.id}-to-${to.id}`;
                const filename = `${cat.id}/${slug}.html`;
                const url = `/${filename}`;
                const title = `${from.name} to ${to.name} Converter – Convert ${from.plural || from.name + 's'} to ${to.plural || to.name + 's'} Instantly`;
                
                const factor = to.factor / from.factor; // This is wrong if factor is absolute to a base.
                // In my units.json, factor is relative to a base (m, sqm, kg, l, kmh, sec, b, j).
                const isTemp = cat.id === 'temperature';
                let actualFactor = 1;
                let formula = '';
                let howTo = '';

                if (isTemp) {
                    // Formula strings for SEO/UI
                    if (from.id === 'c' && to.id === 'f') formula = '°F = (°C × 9/5) + 32';
                    else if (from.id === 'f' && to.id === 'c') formula = '°C = (°F - 32) × 5/9';
                    else if (from.id === 'c' && to.id === 'k') formula = 'K = °C + 273.15';
                    else if (from.id === 'k' && to.id === 'c') formula = '°C = K - 273.15';
                    else if (from.id === 'f' && to.id === 'k') formula = 'K = (°F - 32) × 5/9 + 273.15';
                    else if (from.id === 'k' && to.id === 'f') formula = '°F = (K - 273.15) × 9/5 + 32';
                    
                    howTo = `Converting ${from.name} to ${to.name} involves using a specific temperature scale formula. Use our tool for an instant and accurate calculation.`;
                } else {
                    actualFactor = from.factor / to.factor;
                    formula = `1 ${from.name} = ${actualFactor.toFixed(6).replace(/\.?0+$/, "")} ${to.plural || to.name + 's'}`;
                    howTo = `To convert ${from.plural || from.name + 's'} to ${to.plural || to.name + 's'}, multiply the ${from.name.toLowerCase()} value by ${actualFactor.toFixed(6).replace(/\.?0+$/, "")}. Our online tool makes this calculation instant and error-free.`;
                }

                const toolData = {
                    title: title,
                    metaDescription: `Convert ${from.name.toLowerCase()} to ${to.name.toLowerCase()} instantly with our accurate ${from.id} to ${to.id} converter. Fast, simple, and free online calculator.`,
                    h1: `${from.name} to ${to.name} Converter`,
                    toolShortTitle: `${from.name} to ${to.name}`,
                    categoryName: cat.name,
                    categorySlug: cat.slug,
                    categoryId: cat.id,
                    fromUnitName: from.name,
                    fromUnitPlural: from.plural || from.name + 's',
                    fromUnitShort: from.id,
                    fromUnitId: from.id,
                    toUnitName: to.name,
                    toUnitPlural: to.plural || to.name + 's',
                    toUnitShort: to.id,
                    toUnitId: to.id,
                    factor: actualFactor,
                    formula: formula,
                    howTo: howTo,
                    canonicalUrl: `https://unitconvert.io${url}`,
                    exampleTableRows: isTemp ? generateTempTableRows(from.id, to.id) : generateTableRows(from, to, actualFactor),
                    faqs: generateFAQs(from, to, actualFactor, isTemp),
                    relatedConverters: generateRelated(cat, from, to)
                };

                // Override with specific content if exists
                const specific = contentData.tools[slug];
                if (specific) Object.assign(toolData, specific);

                const pageContent = render(convTemp, toolData);
                const finalHtml = render(baseTemp, {
                    title: toolData.title,
                    metaDescription: toolData.metaDescription,
                    content: pageContent,
                    canonicalUrl: toolData.canonicalUrl
                });

                fs.writeFileSync(path.join(OUTPUT_DIR, filename), finalHtml);
                
                toolsIndex.push({
                    title: `${from.name} to ${to.name}`,
                    url: url,
                    category: cat.name,
                    keywords: [from.name, to.name, `${from.id} to ${to.id}`, `${from.name} to ${to.name}`]
                });
            }
        }

        // 2. Generate Category Page
        const toolLinks = toolsIndex
            .filter(t => t.category === cat.name)
            .map(t => `<a href="${t.url}" class="p-4 bg-gray-50 rounded-xl hover:bg-blue-50 border border-gray-100 transition-colors font-medium text-gray-700">${t.title}</a>`)
            .join('\n');

        const catPageContent = render(catTemp, {
            categoryName: cat.name,
            title: catContent.title,
            description: catContent.description,
            seoContent: catContent.seoContent,
            toolLinks: toolLinks
        });

        const finalCatHtml = render(baseTemp, {
            title: catContent.title,
            metaDescription: catContent.description,
            content: catPageContent,
            canonicalUrl: `https://unitconvert.io/${cat.slug}.html`
        });

        fs.writeFileSync(path.join(OUTPUT_DIR, `${cat.slug}.html`), finalCatHtml);
    });

    // 3. Generate Homepage
    const categoryGrid = unitsData.categories.map(cat => `
        <a href="/${cat.slug}.html" class="glass p-8 rounded-3xl border border-blue-50 card-hover text-center block">
            <div class="w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center text-blue-600 mx-auto mb-4 font-bold text-xl">${cat.name[0]}</div>
            <h3 class="font-bold text-gray-900 mb-1">${cat.name}</h3>
            <p class="text-xs text-gray-400 uppercase tracking-widest">${cat.units.length} Units</p>
        </a>
    `).join('\n');

    const popularTools = toolsIndex.slice(0, 9).map(t => `
        <a href="${t.url}" class="bg-white p-6 rounded-2xl border border-gray-100 card-hover flex items-center justify-between group">
            <div>
                <h3 class="font-bold text-gray-900 group-hover:text-blue-600 transition-colors">${t.title}</h3>
                <p class="text-sm text-gray-400">${t.category}</p>
            </div>
            <svg class="w-5 h-5 text-gray-300 group-hover:text-blue-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
        </a>
    `).join('\n');

    const homeContent = render(homeTemp, {
        categoryGrid: categoryGrid,
        popularTools: popularTools,
        toolsIndex: JSON.stringify(toolsIndex)
    });

    const finalHomeHtml = render(baseTemp, {
        title: contentData.general.siteName + ' - ' + contentData.general.tagline,
        metaDescription: contentData.general.description,
        content: homeContent,
        canonicalUrl: 'https://unitconvert.io/'
    });

    fs.writeFileSync(path.join(OUTPUT_DIR, 'index.html'), finalHomeHtml);

    console.log(`Generated ${toolsIndex.length} converter pages!`);
}

function generateTableRows(from, to, factor) {
    const values = [1, 5, 10, 20, 50, 100];
    return values.map(v => {
        const res = v * factor;
        const formatted = res % 1 === 0 ? res : res.toFixed(4).replace(/\.?0+$/, "");
        return `
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${v} ${from.id}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${formatted} ${to.id}</td>
            </tr>
        `;
    }).join('\n');
}

function generateFAQs(from, to, factor, isTemp) {
    const faqs = [
        {
            q: `How many ${to.plural || to.name + 's'} are in one ${from.name.toLowerCase()}?`,
            a: isTemp ? `Temperature conversions are calculated using a specific formula rather than a simple multiplication factor.` : `There are exactly ${factor.toFixed(6).replace(/\.?0+$/, "")} ${to.plural || to.name + 's'} in one ${from.name.toLowerCase()}.`
        },
        {
            q: `What is the formula to convert ${from.id} to ${to.id}?`,
            a: isTemp ? `The formula depends on the specific temperature units being converted. For example, to convert Celsius to Fahrenheit, we use (C × 9/5) + 32.` : `To convert ${from.name.toLowerCase()} to ${to.name.toLowerCase()}, multiply the ${from.name.toLowerCase()} value by ${factor.toFixed(6).replace(/\.?0+$/, "")}.`
        },
        {
            q: `Is ${from.name} and ${to.name} the same?`,
            a: `No, they are different units of the same category. Our tool helps you accurately calculate the difference between them instantly.`
        }
    ];

    return faqs.map(f => `
        <div class="bg-gray-50 rounded-2xl p-6 border border-gray-100">
            <h3 class="text-lg font-bold text-gray-900 mb-2">${f.q}</h3>
            <p class="text-gray-600">${f.a}</p>
        </div>
    `).join('\n');
}

function generateRelated(cat, from, to) {
    const related = cat.units
        .filter(u => u.id !== from.id && u.id !== to.id)
        .slice(0, 4);

    return related.map(u => `
        <a href="/${cat.id}/${from.id}-to-${u.id}.html" class="p-4 bg-gray-50 rounded-xl hover:bg-blue-50 border border-gray-100 transition-colors font-medium text-gray-700">
            ${from.name} to ${u.name}
        </a>
    `).join('\n');
}

function generateTempTableRows(from, to) {
    const values = [0, 10, 20, 30, 40, 50, 100];
    return values.map(v => {
        let res;
        // Simple conversion logic for table
        if (from === 'c') {
            if (to === 'f') res = (v * 9/5) + 32;
            else if (to === 'k') res = v + 273.15;
        } else if (from === 'f') {
            if (to === 'c') res = (v - 32) * 5/9;
            else if (to === 'k') res = (v - 32) * 5/9 + 273.15;
        } else if (from === 'k') {
            if (to === 'c') res = v - 273.15;
            else if (to === 'f') res = (v - 273.15) * 9/5 + 32;
        }
        const formatted = res % 1 === 0 ? res : res.toFixed(2).replace(/\.?0+$/, "");
        return `
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${v} °${from.toUpperCase()}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${formatted} °${to.toUpperCase()}</td>
            </tr>
        `;
    }).join('\n');
}

generateSite();
