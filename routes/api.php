<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

// Test route - để kiểm tra API có hoạt động
Route::get('/test', function () {
    return response()->json([
        'message' => 'API is working!',
        'timestamp' => now()->toDateTimeString()
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
});