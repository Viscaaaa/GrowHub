<?php

use App\Models\EthicsPolicy;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ethics_policies', function (Blueprint $table) {
            $table->id();
            $table->string('title', 160);
            $table->text('description');
            $table->unsignedInteger('point_deduction')->default(1);
            $table->string('severity', 20)->default('medium'); // low | medium | high
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        $now = now();
        $rows = array_map(
            fn (array $item) => array_merge($item, ['created_at' => $now, 'updated_at' => $now]),
            EthicsPolicy::defaultPolicies()
        );

        DB::table('ethics_policies')->insert($rows);
    }

    public function down(): void
    {
        Schema::dropIfExists('ethics_policies');
    }
};

