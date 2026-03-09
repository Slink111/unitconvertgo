// Performance optimizations for UnitConvert.io
(function() {
    'use strict';
    
    // Preload critical resources
    function preloadResources() {
        // Preload fonts
        const fontLink = document.createElement('link');
        fontLink.rel = 'preload';
        fontLink.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@500;600;700&display=swap';
        fontLink.as = 'style';
        fontLink.onload = function() { this.rel = 'stylesheet'; };
        document.head.appendChild(fontLink);
        
        // Preload critical CSS
        const criticalCSS = document.createElement('link');
        criticalCSS.rel = 'preload';
        criticalCSS.href = '/css/styles.css';
        criticalCSS.as = 'style';
        criticalCSS.onload = function() { this.rel = 'stylesheet'; };
        document.head.appendChild(criticalCSS);
    }
    
    // Optimize image loading
    function optimizeImages() {
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            // Add loading="lazy" to images below fold
            if (!img.hasAttribute('loading')) {
                img.setAttribute('loading', 'lazy');
            }
            
            // Add error handling
            img.addEventListener('error', function() {
                this.style.display = 'none';
            });
        });
    }
    
    // Debounce function for performance
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
    
    // Optimize form inputs
    function optimizeForms() {
        const inputs = document.querySelectorAll('input[type="number"]');
        inputs.forEach(input => {
            // Add input event debouncing for real-time calculations
            const debouncedCalculation = debounce(function() {
                // Trigger calculation logic here
                const event = new Event('change', { bubbles: true });
                input.dispatchEvent(event);
            }, 300);
            
            input.addEventListener('input', debouncedCalculation);
        });
    }
    
    // Initialize performance optimizations
    function init() {
        // Run immediately
        preloadResources();
        optimizeImages();
        optimizeForms();
        
        // Run after DOM is ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
                // Additional optimizations after DOM load
                console.log('Performance optimizations loaded');
            });
        } else {
            console.log('Performance optimizations loaded');
        }
    }
    
    // Initialize
    init();
    
    // Service Worker registration for caching (if available)
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', function() {
            navigator.serviceWorker.register('/sw.js')
                .then(function(registration) {
                    console.log('SW registered: ', registration);
                })
                .catch(function(registrationError) {
                    console.log('SW registration failed: ', registrationError);
                });
        });
    }
})();
