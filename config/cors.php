<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Đây là cấu hình cho middleware HandleCors tích hợp sẵn trong Laravel,
    | xử lý các yêu cầu CORS từ các nguồn gốc khác nhau.
    |
    */

    // Nếu đang chạy trên Railway, vô hiệu hóa các đường dẫn xử lý CORS
    'paths' => env('RAILWAY_ENVIRONMENT') ? [] : ['api/*', 'sanctum/csrf-cookie', '*'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],

    // Chỉ nên có một nguồn '*' hoặc một danh sách cụ thể
    'allowed_origins' => [env('CORS_ALLOW_ORIGIN', '*')],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['Content-Type', 'X-Auth-Token', 'Origin', 'Authorization', 'X-Requested-With', 'Accept'],

    'exposed_headers' => ['Cache-Control', 'Content-Language', 'Content-Type', 'Expires', 'Last-Modified', 'Pragma'],

    'max_age' => 86400,

    'supports_credentials' => false,
];