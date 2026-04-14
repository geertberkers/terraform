<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }

        header h1 {
            color: #333;
            margin-bottom: 10px;
        }

        header p {
            color: #666;
            font-size: 14px;
        }

        .main-grid {
            display: grid;
            grid-template-columns: 1fr 2fr;
            gap: 30px;
            margin-bottom: 30px;
        }

        .panel {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        .panel h2 {
            color: #333;
            font-size: 18px;
            margin-bottom: 20px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }

        .database-list {
            list-style: none;
        }

        .database-list li {
            padding: 12px;
            margin-bottom: 8px;
            background: #f5f5f5;
            border-left: 4px solid #667eea;
            cursor: pointer;
            border-radius: 4px;
            transition: all 0.3s ease;
        }

        .database-list li:hover {
            background: #667eea;
            color: white;
            transform: translateX(5px);
        }

        .database-list li.active {
            background: #667eea;
            color: white;
        }

        .query-panel {
            display: flex;
            flex-direction: column;
        }

        .form-group {
            margin-bottom: 15px;
        }

        label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
            font-size: 14px;
        }

        textarea, input, select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            resize: vertical;
        }

        textarea {
            height: 200px;
        }

        button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: transform 0.2s ease;
        }

        button:hover {
            transform: scale(1.02);
        }

        button:active {
            transform: scale(0.98);
        }

        .button-group {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }

        .results-panel {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }

        .results-panel h2 {
            color: #333;
            margin-bottom: 20px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        th {
            background: #f5f5f5;
            font-weight: 600;
            color: #333;
        }

        tr:hover {
            background: #f9f9f9;
        }

        .loading {
            display: none;
            text-align: center;
            padding: 20px;
            color: #667eea;
        }

        .loading.active {
            display: block;
        }

        .spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .no-results {
            text-align: center;
            padding: 40px;
            color: #999;
        }

        .error {
            background: #fee;
            color: #c33;
            padding: 15px;
            border-radius: 4px;
            border-left: 4px solid #c33;
            margin-bottom: 15px;
            display: none;
        }

        .error.active {
            display: block;
        }

        @media (max-width: 768px) {
            .main-grid {
                grid-template-columns: 1fr;
            }

            .button-group {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🗄️ ${title}</h1>
            <p>Multi-database query interface with Azure Managed Identity</p>
        </header>

        <div class="main-grid">
            <!-- Connection Status -->
            <div class="panel" style="grid-column: 1 / -1;">
                <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #667eea; margin-bottom: 20px; padding-bottom: 10px;">
                    <h2 style="border-bottom: none; margin-bottom: 0; padding-bottom: 0;">🟢 Connection Status</h2>
                    <button type="button" onclick="checkConnections()" style="padding: 8px 15px;">🔄 Refresh</button>
                </div>
                <div id="connectionStatusContainer" style="display: flex; gap: 15px; flex-wrap: wrap;">
                    <div style="flex: 1; min-width: 200px; padding: 15px; background: #f5f5f5; border-radius: 4px;">
                        Loading status...
                    </div>
                </div>
            </div>

            <!-- Database Selector -->
            <div class="panel">
                <h2>📊 Databases</h2>
                <ul class="database-list">
                    <#list databases as db>
                        <li data-database="${db?lower_case}">${db}</li>
                    </#list>
                </ul>
                <div style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 4px;">
                    <p style="font-size: 12px; color: #666;">
                        <strong>Total Databases:</strong> ${databases?size}
                    </p>
                </div>
            </div>

            <!-- Query Interface -->
            <div class="panel">
                <h2>⚙️ Execute Query</h2>
                <form id="queryForm">
                    <div class="error" id="errorBox"></div>

                    <div class="form-group">
                        <label for="selectedDb">Selected Database:</label>
                        <input type="text" id="selectedDb" readonly style="background: #f5f5f5; color: #666;">
                    </div>

                    <div class="form-group">
                        <label for="queryType">Operation Type:</label>
                        <select id="queryType" onchange="toggleQueryMode()">
                            <option value="select">SELECT (Read)</option>
                            <option value="update">INSERT/UPDATE/DELETE (Write)</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="queryText">SQL Query:</label>
                        <textarea id="queryText" placeholder="Enter your SQL query here..."></textarea>
                    </div>

                    <div class="form-group" style="background: #f5f5f5; padding: 10px; border-radius: 4px; margin-bottom: 15px;">
                        <label style="font-size: 12px; margin-bottom: 8px;">Quick Examples (Click to Fill):</label>
                        <div id="exampleBtnContainer" style="display: flex; gap: 8px; flex-wrap: wrap;">
                            <span style="font-size:11px;color:#999;">Select a database to see examples</span>
                        </div>
                    </div>

                    <div class="button-group">
                        <button type="button" onclick="executeQuery()">▶️ Execute</button>
                        <button type="button" onclick="clearQuery()">🗑️ Clear</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Results -->
        <div class="results-panel">
            <h2>📋 Results</h2>
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>Executing query...</p>
            </div>
            <div id="resultsContainer" class="no-results">Select a database and enter a query to see results</div>
        </div>
    </div>

    <script>
        <#noparse>
        let selectedDatabase = null;

        // Per-database SQL examples with correct syntax for each engine
        const dbExamples = {
            postgresql: {
                create: "CREATE TABLE persons (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));",
                insert: "INSERT INTO persons (name, email) VALUES ('Alice Smith', 'alice@example.com');",
                select: "SELECT * FROM persons;",
                delete: "DELETE FROM persons WHERE name = 'Alice Smith';",
                drop: "DROP TABLE IF EXISTS persons;"
            },
            mysql: {
                create: "CREATE TABLE persons (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));",
                insert: "INSERT INTO persons (name, email) VALUES ('Alice Smith', 'alice@example.com');",
                select: "SELECT * FROM persons;",
                delete: "DELETE FROM persons WHERE name = 'Alice Smith';",
                drop: "DROP TABLE IF EXISTS persons;"
            },
            sqlserver: {
                create: "CREATE TABLE persons (id INT IDENTITY(1,1) PRIMARY KEY, name NVARCHAR(255), email NVARCHAR(255));",
                insert: "INSERT INTO persons (name, email) VALUES ('Alice Smith', 'alice@example.com');",
                select: "SELECT * FROM persons;",
                delete: "DELETE FROM persons WHERE name = 'Alice Smith';",
                drop: "IF OBJECT_ID('persons', 'U') IS NOT NULL DROP TABLE persons;"
            },
            cosmosdb: {
                create: "-- CosmosDB: Create Table (container managed by Terraform)\n{\"operation\": \"create\", \"entity\": \"persons\"}",
                insert: "-- CosmosDB: Insert Person (upsert document)\n{\"id\": \"2\", \"name\": \"Bob Jones\", \"email\": \"bob@example.com\"}",
                select: "SELECT * FROM c",
                delete: "-- CosmosDB: Delete Person by id\n{\"id\": \"2\"}",
                drop: "-- CosmosDB: Drop Table (container retained)\n{\"operation\": \"drop\", \"entity\": \"persons\"}"
            }
        };

        // Database selection
        document.querySelectorAll('.database-list li').forEach(li => {
            li.addEventListener('click', function() {
                document.querySelectorAll('.database-list li').forEach(el => el.classList.remove('active'));
                this.classList.add('active');
                selectedDatabase = this.dataset.database;
                document.getElementById('selectedDb').value = selectedDatabase.charAt(0).toUpperCase() + selectedDatabase.slice(1);
                updateExampleButtons();
            });
        });

        function updateExampleButtons() {
            const container = document.getElementById('exampleBtnContainer');
            if (!selectedDatabase || !dbExamples[selectedDatabase]) {
                container.innerHTML = '<span style="font-size:11px;color:#999;">Select a database to see examples</span>';
                return;
            }
            const ex = dbExamples[selectedDatabase];
            container.innerHTML = `
                <button type="button" class="example-btn" onclick="fillExample('${escapeJs(ex.create)}', 'update')" style="padding: 5px 10px; font-size: 11px; background: #ddd; color: #333;">Create Table</button>
                <button type="button" class="example-btn" onclick="fillExample('${escapeJs(ex.insert)}', 'update')" style="padding: 5px 10px; font-size: 11px; background: #ddd; color: #333;">Insert Person</button>
                <button type="button" class="example-btn" onclick="fillExample('${escapeJs(ex.select)}', 'select')" style="padding: 5px 10px; font-size: 11px; background: #ddd; color: #333;">Select Persons</button>
                <button type="button" class="example-btn" onclick="fillExample('${escapeJs(ex.delete)}', 'update')" style="padding: 5px 10px; font-size: 11px; background: #ddd; color: #333;">Delete Person</button>
                <button type="button" class="example-btn" onclick="fillExample('${escapeJs(ex.drop)}', 'update')" style="padding: 5px 10px; font-size: 11px; background: #ddd; color: #333;">Drop Table</button>
            `;
        }

        function escapeJs(str) {
            return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n');
        }

        function toggleQueryMode() {
            const mode = document.getElementById('queryType').value;
            const placeholder = mode === 'select' 
                ? 'e.g., SELECT * FROM users LIMIT 10;'
                : 'e.g., INSERT INTO users (name, email) VALUES (\'John\', \'john@example.com\');';
            document.getElementById('queryText').placeholder = placeholder;
        }

        async function executeQuery() {
            if (!selectedDatabase) {
                showError('Please select a database first');
                return;
            }

            const queryText = document.getElementById('queryText').value.trim();
            if (!queryText) {
                showError('Please enter a query');
                return;
            }

            const mode = document.getElementById('queryType').value;
            showLoading(true);
            hideError();
            document.getElementById('resultsContainer').innerHTML =
                '<div class="no-results">Running query...</div>';

            try {
                let endpoint, body;
                if (mode === 'select') {
                    endpoint = '/api/database/query';
                    body = { database: selectedDatabase, query: queryText };
                } else {
                    endpoint = '/api/database/execute';
                    body = { database: selectedDatabase, sql: queryText, params: [] };
                }

                const response = await fetch(endpoint, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body)
                });

                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.message || 'Query execution failed');
                }

                const result = await response.json();
                displayResults(result);
            } catch (error) {
                showError(error.message);
                console.error('Error:', error);
            } finally {
                showLoading(false);
            }
        }

        function displayResults(result) {
            // Update/Insert/Delete response (has message and affectedRows, no rows)
            if (result.rows === undefined) {
                document.getElementById('resultsContainer').innerHTML = `
                    <div style="padding: 20px; background: #e8f5e9; border-radius: 4px;">
                        <p style="color: #2e7d32; font-weight: 600;">✓ Success</p>
                        <p>${result.message || 'Operation completed successfully'}</p>
                    </div>
                `;
                return;
            }

            if (result.rows.length === 0) {
                document.getElementById('resultsContainer').innerHTML = '<div class="no-results">No results found</div>';
                return;
            }

            let html = `<p style="margin-bottom: 15px; color: #666; font-size: 12px;">
                <strong>${result.rowCount}</strong> row(s) returned from <strong>${result.database}</strong>
            </p>`;
            
            html += '<table><thead><tr>';
            result.columns.forEach(col => {
                html += `<th>${col}</th>`;
            });
            html += '</tr></thead><tbody>';

            result.rows.forEach(row => {
                html += '<tr>';
                result.columns.forEach(col => {
                    const value = row[col];
                    html += `<td>${escapeHtml(value !== null ? value : 'NULL')}</td>`;
                });
                html += '</tr>';
            });

            html += '</tbody></table>';
            document.getElementById('resultsContainer').innerHTML = html;
        }

        function showLoading(show) {
            document.getElementById('loading').classList.toggle('active', show);
        }

        function showError(message) {
            const errorBox = document.getElementById('errorBox');
            errorBox.textContent = message;
            errorBox.classList.add('active');
        }

        function hideError() {
            document.getElementById('errorBox').classList.remove('active');
        }

        function clearQuery() {
            document.getElementById('queryText').value = '';
            document.getElementById('resultsContainer').innerHTML = 
                '<div class="no-results">Select a database and enter a query to see results</div>';
            hideError();
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function fillExample(sql, mode) {
            document.getElementById('queryType').value = mode;
            document.getElementById('queryText').value = sql;
            toggleQueryMode();
            
            const ta = document.getElementById('queryText');
            ta.style.transition = 'background 0.2s';
            ta.style.background = '#e8f5e9';
            setTimeout(() => ta.style.background = 'white', 300);
        }

        async function checkConnections() {
            const container = document.getElementById('connectionStatusContainer');
            container.innerHTML = '<div style="flex: 1; padding: 15px; background: #f5f5f5; border-radius: 4px;">Testing connections... <div class="spinner" style="vertical-align: middle; width: 15px; height: 15px; border-width: 2px;"></div></div>';
            
            try {
                const response = await fetch('/api/database/example-data');
                if (!response.ok) throw new Error('Failed to fetch connection status');
                const result = await response.json();
                const data = result.example_data;
                
                let html = '';
                for (const [db, status] of Object.entries(data)) {
                    const isHealthy = status.isAlive === true;
                    const bgColor = isHealthy ? '#e8f5e9' : '#fee';
                    const color = isHealthy ? '#2e7d32' : '#c33';
                    const icon = isHealthy ? '✅' : '❌';
                    const detail = isHealthy ? status.dbVersion : status.error;
                    
                    html += `
                        <div style="flex: 1; min-width: 250px; padding: 15px; background: ${bgColor}; border-left: 4px solid ${color}; border-radius: 4px;">
                            <h3 style="color: ${color}; margin-bottom: 8px; font-size: 16px;">${icon} ${db.toUpperCase()}</h3>
                            <p style="font-size: 12px; color: #666; word-break: break-all;">${typeof detail === 'string' ? escapeHtml(detail) : escapeHtml(JSON.stringify(detail))}</p>
                        </div>
                    `;
                }
                container.innerHTML = html;
            } catch (err) {
                container.innerHTML = `<div style="color: #c33; padding: 15px;">Failed to load connection status: ${escapeHtml(err.message)}</div>`;
            }
        }

        // Auto-select first database and load status
        window.addEventListener('load', () => {
            const first = document.querySelector('.database-list li');
            if (first) first.click();
            checkConnections();
        });
        </#noparse>
    </script>
</body>
</html>
