<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class StripDuplicateCorsHeaders
{
    /**
     * Xử lý request và loại bỏ header CORS trùng lặp
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Xử lý request như bình thường
        $response = $next($request);

        // Nếu là preflight request OPTIONS
        if ($request->isMethod('OPTIONS')) {
            // Xóa tất cả các header CORS
            $response->headers->remove('Access-Control-Allow-Origin');
            $response->headers->remove('Access-Control-Allow-Methods');
            $response->headers->remove('Access-Control-Allow-Headers');
            
            // Thiết lập lại chỉ một lần
            $response->headers->set('Access-Control-Allow-Origin', '*');
            $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
            $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, X-CSRF-TOKEN');
            $response->headers->set('Access-Control-Max-Age', '86400');
        } else {
            // Xóa và thiết lập lại header CORS cho các request thông thường
            if ($response->headers->has('Access-Control-Allow-Origin')) {
                $response->headers->remove('Access-Control-Allow-Origin');
                $response->headers->set('Access-Control-Allow-Origin', '*');
            }
        }

        return $response;
    }
}
