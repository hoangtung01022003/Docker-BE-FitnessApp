<?php

namespace App\Http\Controllers;

use App\Models\UserProfile;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    /**
     * Lưu hoặc cập nhật thông tin profile của người dùng
     */
    public function saveProfile(Request $request)
    {
        try {
            $validated = $request->validate([
                'birthday' => 'nullable|date',
                'height' => 'nullable|numeric|min:0|max:300',
                'weight' => 'nullable|numeric|min:0|max:500',
                'gender' => 'nullable|in:Male,Female',
            ]);

            // Tìm hoặc tạo mới profile cho user
            $profile = UserProfile::updateOrCreate(
                ['user_id' => auth()->id()], // điều kiện tìm kiếm
                $validated // dữ liệu cập nhật
            );

            return response()->json([
                'message' => 'Profile saved successfully',
                'profile' => $profile
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to save profile',
                'error' => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Lấy thông tin profile của người dùng hiện tại
     */
    public function getProfile()
    {
        try {
            $user = auth()->user();
            $profile = $user->profile;
            
            if (!$profile) {
                return response()->json([
                    'message' => 'Profile not found',
                    'profile' => null
                ]);
            }

            return response()->json([
                'message' => 'Profile retrieved successfully',
                'profile' => $profile
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to get profile',
                'error' => $e->getMessage()
            ], 400);
        }
    }
}