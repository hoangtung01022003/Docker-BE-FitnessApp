<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\DB as FacadesDB;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot()
    {
        // Chỉ cấu hình CORS nếu không phải môi trường Railway
        // hoặc Railway yêu cầu sử dụng cấu hình CORS tùy chỉnh
        if (!env('RAILWAY_ENVIRONMENT') || env('RAILWAY_USE_CUSTOM_CORS')) {
            $this->configureCorsForAll();
        }

        // Thử kết nối với MySQL nếu có thông tin
        if (env('MYSQLHOST') || env('RAILWAY_TCP_PROXY_DOMAIN')) {
            try {
                // Thử dùng RAILWAY_TCP_PROXY_DOMAIN thay vì MYSQLHOST
                if (env('RAILWAY_TCP_PROXY_DOMAIN')) {
                    config([
                        'database.default' => 'mysql',
                        'database.connections.mysql.host' => env('RAILWAY_TCP_PROXY_DOMAIN'),
                        'database.connections.mysql.port' => env('RAILWAY_TCP_PROXY_PORT', 3306)
                    ]);
                } else {
                    config(['database.default' => 'mysql']);
                }

                // Kiểm tra kết nối
                FacadesDB::connection('mysql')->getPdo();
            } catch (\Exception $e) {
                // Lỗi kết nối MySQL, fallback về SQLite
                \Log::warning("Không thể kết nối MySQL: " . $e->getMessage());
                \Log::info("Chuyển sang sử dụng SQLite...");
                config(['database.default' => 'sqlite']);
            }
        }
    }

    /**
     * Cấu hình CORS cho tất cả môi trường
     */
    protected function configureCorsForAll()
    {
        // Đối với Railway, chúng ta cần đảm bảo không có header trùng lặp
        if (env('RAILWAY_ENVIRONMENT')) {
            // Tắt hoàn toàn middleware CORS của Laravel nếu đang trên Railway
            // Chúng ta sẽ dùng middleware riêng
            app('router')->middlewareGroup('api', []);
            return;
        }
        
        // Cấu hình CORS bình thường cho môi trường khác
        config([
            'cors.paths' => ['api/*', 'sanctum/csrf-cookie', '*'],
            'cors.allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            'cors.allowed_origins' => ['*'],
            'cors.allowed_origins_patterns' => [],
            'cors.allowed_headers' => ['Content-Type', 'X-Auth-Token', 'Origin', 'Authorization', 'X-Requested-With', 'Accept'],
            'cors.exposed_headers' => ['Cache-Control', 'Content-Language', 'Content-Type', 'Expires', 'Last-Modified', 'Pragma'],
            'cors.max_age' => 86400,
            'cors.supports_credentials' => false,
        ]);
    }
}
