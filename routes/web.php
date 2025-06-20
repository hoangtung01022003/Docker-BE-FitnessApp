<?php

use Illuminate\Support\Facades\Route;

// Route đơn giản cho trang chủ
Route::get('/', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'API is running'
    ]);
});

// Health check đơn giản
Route::get('/health', function() {
    return 'OK';
});
