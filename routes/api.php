<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\ProfileController;

// Health check endpoint cho Railway
Route::get('/health', function() {
    try {
        // Thử kết nối với cơ sở dữ liệu
        $dbStatus = "unknown";
        try {
            DB::connection()->getPdo();
            $dbStatus = "connected";
        } catch (\Exception $e) {
            $dbStatus = "error: " . $e->getMessage();
        }

        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
            'environment' => [
                'app_env' => env('APP_ENV'),
                'db_connection' => config('database.default'),
                'db_host' => env('DB_HOST'),
                'db_database' => env('DB_DATABASE')
            ],
            'database_status' => $dbStatus
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage()
        ], 500);
    }
});

// Thêm route mới ở root level cho health check
Route::get('/', function() {
    return response()->json([
        'message' => 'API is working!',
        'timestamp' => now()->toDateTimeString(),
        'health_status' => 'ok'
    ]);
});

// Auth routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/update-profile', [AuthController::class, 'updateProfile']);

    // Profile routes
    Route::post('/profile', [ProfileController::class, 'saveProfile']);
    Route::get('/profile', [ProfileController::class, 'getProfile']);
});

// Route kiểm tra kết nối database
Route::get('/db-check', function () {
    try {
        // Kiểm tra kết nối database
        DB::connection()->getPdo();

        return response()->json([
            'status' => 'success',
            'message' => 'Kết nối database thành công!',
            'connection' => config('database.default'),
            'database' => DB::connection()->getDatabaseName(),
            'environment' => [
                'DB_CONNECTION' => env('DB_CONNECTION'),
                'DB_HOST' => env('DB_HOST'),
                'DB_PORT' => env('DB_PORT'),
                'DB_DATABASE' => env('DB_DATABASE'),
                'DB_USERNAME' => env('DB_USERNAME'),
                'MYSQL_VARIABLES' => [
                    'MYSQLHOST' => env('MYSQLHOST'),
                    'MYSQLPORT' => env('MYSQLPORT'),
                    'MYSQLDATABASE' => env('MYSQLDATABASE'),
                    'MYSQLUSER' => env('MYSQLUSER'),
                ]
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Không thể kết nối database!',
            'error' => $e->getMessage(),
            'environment' => [
                'DB_CONNECTION' => env('DB_CONNECTION'),
                'DB_HOST' => env('DB_HOST'),
                'DB_PORT' => env('DB_PORT'),
                'DB_DATABASE' => env('DB_DATABASE'),
                'DB_USERNAME' => env('DB_USERNAME'),
                'MYSQL_VARIABLES' => [
                    'MYSQLHOST' => env('MYSQLHOST'),
                    'MYSQLPORT' => env('MYSQLPORT'),
                    'MYSQLDATABASE' => env('MYSQLDATABASE'),
                    'MYSQLUSER' => env('MYSQLUSER'),
                ]
            ]
        ], 500);
    }
});
// Route để sửa kết nối MySQL
Route::get('/fix-mysql', function (Request $request) {
    // Tìm kiếm và hiển thị tất cả biến môi trường có thể sử dụng
    $allEnvVars = [];
    foreach ($_ENV as $key => $value) {
        if (strpos($key, 'MYSQL') !== false || 
            strpos($key, 'DB_') !== false || 
            strpos($key, 'RAILWAY') !== false ||
            strpos($key, 'HOST') !== false ||
            strpos($key, 'DATABASE') !== false) {
            $allEnvVars[$key] = $value;
        }
    }
    
    // Thử kết nối với các host khác nhau
    $connections = [];
    $hosts = [
        'original' => env('MYSQLHOST'),
        'tcp_proxy' => env('RAILWAY_TCP_PROXY_DOMAIN'),
        'direct_ip' => env('MYSQL_SERVICE_HOST'),
        'localhost' => 'localhost',
        'mysql' => 'mysql'
    ];
    
    foreach ($hosts as $name => $host) {
        if (empty($host)) continue;
        
        try {
            $dbConfig = [
                'driver' => 'mysql',
                'host' => $host,
                'port' => env('MYSQLPORT', env('RAILWAY_TCP_PROXY_PORT', 3306)),
                'database' => env('MYSQLDATABASE', 'railway'),
                'username' => env('MYSQLUSER', 'root'),
                'password' => env('MYSQLPASSWORD', env('MYSQL_ROOT_PASSWORD')),
                'charset' => 'utf8mb4',
                'collation' => 'utf8mb4_unicode_ci',
                'prefix' => '',
            ];
            
            // Thử kết nối
            $pdo = new PDO(
                "mysql:host={$dbConfig['host']};port={$dbConfig['port']};dbname={$dbConfig['database']}",
                $dbConfig['username'],
                $dbConfig['password']
            );
            
            $connections[$name] = [
                'status' => 'success',
                'message' => "Kết nối thành công với host $host!",
                'config' => $dbConfig
            ];
            
            // Cập nhật cấu hình database nếu kết nối thành công
            if ($request->query('apply') === 'true') {
                config(['database.connections.mysql.host' => $host]);
                DB::purge('mysql');
                DB::reconnect('mysql');
                $connections[$name]['applied'] = true;
            }
        } catch (\Exception $e) {
            $connections[$name] = [
                'status' => 'error',
                'message' => $e->getMessage(),
                'host' => $host
            ];
        }
    }
    
    // Tạo file cấu hình mới nếu cần
    if ($request->query('update_env') === 'true' && !empty($connections)) {
        // Tìm kết nối thành công đầu tiên
        $successConn = null;
        foreach ($connections as $name => $conn) {
            if ($conn['status'] === 'success') {
                $successConn = $conn;
                break;
            }
        }
        
        if ($successConn) {
            // Tạo nội dung .env
            $envContent = file_get_contents(base_path('.env'));
            $newEnvContent = preg_replace(
                '/DB_HOST=.*/',
                'DB_HOST=' . $successConn['config']['host'],
                $envContent
            );
            
            // Ghi file .env mới
            file_put_contents(base_path('.env'), $newEnvContent);
            
            return response()->json([
                'message' => 'Đã cập nhật file .env với host thành công: ' . $successConn['config']['host'],
                'all_env_vars' => $allEnvVars,
                'connection_tests' => $connections
            ]);
        }
    }
    
    return response()->json([
        'message' => 'Kiểm tra kết nối MySQL với các host khác nhau',
        'note' => 'Sử dụng ?apply=true để áp dụng kết nối thành công; ?update_env=true để cập nhật file .env',
        'current_config' => [
            'driver' => DB::connection()->getDriverName(),
            'host' => DB::connection()->getConfig('host'),
            'database' => DB::connection()->getDatabaseName()
        ],
        'all_env_vars' => $allEnvVars,
        'connection_tests' => $connections
    ]);
});


// Terminal DB endpoint
Route::get('/db-terminal', function (Request $request) {
    // Kiểm tra xem ứng dụng có đang chạy trong môi trường dev/testing không
    if (app()->environment('production') && !env('ALLOW_DB_TERMINAL', false)) {
        return response()->json(['error' => 'Endpoint này chỉ có sẵn trong môi trường phát triển hoặc khi ALLOW_DB_TERMINAL=true'], 403);
    }

    $connection = DB::connection()->getDriverName();
    
    // Mặc định command dựa trên loại database
    $defaultCommand = $connection === 'sqlite' 
        ? "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        : 'SHOW TABLES';
    
    $command = $request->query('command', $defaultCommand);
    $output = [];
    $status = 'success';
    $message = 'Lệnh đã được thực thi';

    try {
        // Kiểm tra kết nối
        if (DB::connection()->getDatabaseName()) {
            // Xác định loại lệnh SQL được gửi đến
            $commandType = strtoupper(substr(trim($command), 0, 6));
            
            // Danh sách các lệnh được phép
            $allowedPrefixes = [
                'SELECT', 'SHOW', 'DESCRI', 'PRAGMA', // DESCRIBE được rút gọn để match
            ];
            
            $allowed = false;
            foreach ($allowedPrefixes as $prefix) {
                if (strpos($commandType, $prefix) === 0) {
                    $allowed = true;
                    break;
                }
            }
            
            if ($allowed) {
                $output = DB::select($command);
            } else {
                // Cho phép thêm các lệnh khác nếu có flag
                $allowedCommands = ['CREATE', 'INSERT', 'UPDATE', 'DELETE', 'ALTER'];
                $firstWord = strtoupper(substr(trim($command), 0, strpos(trim($command) . ' ', ' ')));

                if (in_array($firstWord, $allowedCommands) && env('ALLOW_DB_TERMINAL_ALL', false)) {
                    $output = DB::statement($command) ? ['Query executed successfully'] : ['Query failed'];
                } else {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Chỉ hỗ trợ các lệnh SELECT, SHOW, PRAGMA và DESCRIBE vì lý do bảo mật'
                    ], 400);
                }
            }
        }
    } catch (\Exception $e) {
        $status = 'error';
        $message = $e->getMessage();
    }

    // Lấy thông tin kết nối từ biến môi trường
    $host = env('MYSQLHOST', env('DB_HOST', '127.0.0.1'));
    $port = env('MYSQLPORT', env('DB_PORT', '3306'));
    $database = env('MYSQLDATABASE', env('DB_DATABASE', 'laravel'));
    $username = env('MYSQLUSER', env('DB_USERNAME', 'root'));

    return response()->json([
        'status' => $status,
        'message' => $message,
        'command' => $command,
        'driver' => $connection,
        'result' => $output,
        'connection_info' => [
            'driver' => $connection,
            'host' => $host,
            'port' => $port,
            'database' => $database,
            'username' => $username,
            'connection' => config('database.default')
        ]
    ]);
});
// DB Admin - Trang quản lý database đơn giản (MySQL)
// DB Admin - Trang quản lý database đơn giản
Route::get('/db-admin', function () {
    // Bỏ abort() để tránh lỗi trong production
    if (app()->environment('production') && !env('ALLOW_DB_ADMIN', true)) {
        return response()->json(['error' => 'Trang này chỉ có sẵn trong môi trường phát triển hoặc khi ALLOW_DB_ADMIN=true'], 403);
    }

    // Bọc toàn bộ logic trong try-catch để bắt mọi lỗi có thể xảy ra
    try {
        // Xác định loại kết nối database
        $connection = DB::connection()->getDriverName();
        $dbName = DB::connection()->getDatabaseName();
        
        // Lấy danh sách bảng dựa trên loại database
        if ($connection === 'sqlite') {
            $tables = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
            $tableField = 'name';
        } else {
            // MySQL hoặc các database khác
            $tables = DB::select('SHOW TABLES');
            $tableField = 'Tables_in_' . $dbName;
        }

        // Tạo HTML cho trang admin đơn giản
        $html = '<!DOCTYPE html>
        <html>
        <head>
            <title>Database Admin - ' . strtoupper($connection) . '</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
                h1 { color: #333; }
                .table-list { margin-bottom: 20px; }
                .table-item { background: #f1f1f1; padding: 10px; margin: 5px 0; cursor: pointer; }
                .query-form { margin-bottom: 20px; }
                textarea { width: 100%; height: 100px; }
                button { padding: 10px; background: #4CAF50; color: white; border: none; cursor: pointer; }
                .result { background: #f8f8f8; padding: 10px; border: 1px solid #ddd; overflow: auto; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
                .debug-info { background: #fff8e1; padding: 10px; margin-top: 20px; border: 1px solid #ffe082; }
            </style>
        </head>
        <body>
            <h1>Database Admin (' . strtoupper($connection) . ')</h1>
            <div class="db-info">
                <p>Connection Type: <strong>' . strtoupper($connection) . '</strong></p>
                <p>Database: <strong>' . $dbName . '</strong></p>
                <p>Host: <strong>' . env('MYSQLHOST', env('DB_HOST', 'localhost')) . '</strong></p>
            </div>
            
            <div class="debug-info">
                <h3>Thông tin kết nối:</h3>
                <p>DB_CONNECTION: ' . env('DB_CONNECTION', 'not set') . '</p>
                <p>MYSQLHOST: ' . env('MYSQLHOST', 'not set') . '</p>
                <p>MYSQLPORT: ' . env('MYSQLPORT', 'not set') . '</p>
                <p>MYSQLDATABASE: ' . env('MYSQLDATABASE', 'not set') . '</p>
                <p>Database config default: ' . config('database.default') . '</p>
            </div>
            
            <div class="table-list">
                <h2>Tables</h2>';

        if (count($tables) > 0) {
            foreach ($tables as $table) {
                // Xử lý đặc biệt cho từng loại database
                $tableName = isset($table->$tableField) ? $table->$tableField : array_values((array)$table)[0];
                $html .= '<div class="table-item" onclick="loadTable(\'' . $tableName . '\')">' . $tableName . '</div>';
            }
        } else {
            $html .= '<p>Không tìm thấy bảng nào trong database.</p>';
        }

        $html .= '</div>
            <div class="query-form">
                <h2>SQL Query</h2>
                <form id="query-form">
                    <textarea id="query" placeholder="' . ($connection === 'sqlite' ? 'SELECT * FROM sqlite_master' : 'SELECT * FROM users LIMIT 10') . '"></textarea>
                    <button type="submit">Execute</button>
                </form>
            </div>
            <div id="result" class="result"></div>
            
            <script>
            // Lưu trữ loại kết nối để sử dụng trong JavaScript
            const dbConnection = "' . $connection . '";
            
            function loadTable(tableName) {
                let query = "";
                if (dbConnection === "sqlite") {
                    query = `SELECT * FROM ${tableName} LIMIT 10`;
                } else {
                    query = `SELECT * FROM ${tableName} LIMIT 10`;
                }
                document.getElementById("query").value = query;
                document.getElementById("query-form").dispatchEvent(new Event("submit"));
            }
            
            document.getElementById("query-form").addEventListener("submit", function(e) {
                e.preventDefault();
                const query = document.getElementById("query").value;
                
                fetch(`/api/db-terminal?command=${encodeURIComponent(query)}`)
                    .then(response => response.json())
                    .then(data => {
                        const resultDiv = document.getElementById("result");
                        
                        if (data.status === "error") {
                            resultDiv.innerHTML = `<p style="color: red">${data.message}</p>`;
                            return;
                        }
                        
                        if (!data.result || data.result.length === 0) {
                            resultDiv.innerHTML = "<p>No results found</p>";
                            return;
                        }
                        
                        // Create table
                        let table = "<table><tr>";
                        const firstRow = data.result[0];
                        
                        // Headers
                        for (const key in firstRow) {
                            table += `<th>${key}</th>`;
                        }
                        table += "</tr>";
                        
                        // Rows
                        data.result.forEach(row => {
                            table += "<tr>";
                            for (const key in row) {
                                table += `<td>${row[key]}</td>`;
                            }
                            table += "</tr>";
                        });
                        
                        table += "</table>";
                        resultDiv.innerHTML = table;
                    })
                    .catch(error => {
                        document.getElementById("result").innerHTML = `<p style="color: red">Error: ${error.message}</p>`;
                    });
            });
            </script>
        </body>
        </html>';

        return response($html)->header('Content-Type', 'text/html');
    } catch (\Exception $e) {
        // Trả về lỗi chi tiết hơn và thông tin về kết nối
        return response()->json([
            'error' => 'Lỗi khi tạo trang admin: ' . $e->getMessage(),
            'trace' => app()->environment('production') ? null : $e->getTraceAsString(),
            'connection' => config('database.default'),
            'db_connection_env' => env('DB_CONNECTION'),
            'mysql_host_env' => env('MYSQLHOST'),
            'mysql_database_env' => env('MYSQLDATABASE'),
            'db_status' => 'Kiểm tra kết nối database và biến môi trường'
        ], 500);
    }
});
