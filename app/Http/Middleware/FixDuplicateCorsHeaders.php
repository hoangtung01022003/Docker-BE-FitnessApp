<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class FixDuplicateCorsHeaders
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        
        // Nếu đang chạy trên Railway, đảm bảo không có header CORS trùng lặp
        if (env('RAILWAY_ENVIRONMENT')) {
            // Lấy header hiện có
            $corsOrigin = $response->headers->get('Access-Control-Allow-Origin');
            
            // Nếu có nhiều giá trị '*', chỉ giữ lại một
            if ($corsOrigin && strpos($corsOrigin, '*, *') !== false) {
                $response->headers->set('Access-Control-Allow-Origin', '*');
            }
        }
        
        return $response;
    }
}
