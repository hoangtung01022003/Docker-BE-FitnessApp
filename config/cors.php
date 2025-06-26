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

    // Kích hoạt xử lý CORS trong Laravel để có cách xử lý nhất quán
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],

    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['Content-Type', 'X-Auth-Token', 'Origin', 'Authorization', 'X-Requested-With', 'Accept'],

    'exposed_headers' => ['Cache-Control', 'Content-Language', 'Content-Type', 'Expires', 'Last-Modified', 'Pragma'],

    'max_age' => 86400,

    'supports_credentials' => false,
];