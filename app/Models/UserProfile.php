<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'birthday',
        'height',
        'weight',
        'gender',
        'fitness_level'
    ];

    protected $casts = [
        'birthday' => 'date',
        'height' => 'decimal:2',
        'weight' => 'decimal:2',
    ];

    /**
     * Get the user that owns the profile.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}