export function getPerplexityPopupContent(): string {
	return `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Perplexity Debug</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
                h1 { color: #333; }
            </style>
        </head>
        <body>
            <h1>Perplexity Debug</h1>
            <p>This is the Perplexity popup content. If you can see this, the content is loading correctly.</p>
            <p id="timestamp"></p>
            <script>
                console.log("Perplexity popup loaded at:", new Date().toISOString());
                document.getElementById('timestamp').textContent = 'Loaded at: ' + new Date().toISOString();
                window.onerror = function(message, source, lineno, colno, error) {
                    console.error("Error in Perplexity popup:", message, "at", source, ":", lineno);
                };
            </script>
        </body>
        </html>
    `;
}
