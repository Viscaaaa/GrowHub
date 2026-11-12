<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('point_rules')) {
            DB::table('point_rules')
                ->where('action', 'course_completed')
                ->where('description', 'Poin kelulusan materi mandiri retail di Learning Center.')
                ->update([
                    'description' => 'Poin kelulusan materi mandiri di Learning Center.',
                    'updated_at' => now(),
                ]);
        }

        if (Schema::hasTable('level_rules')) {
            DB::table('level_rules')
                ->where('description', 'Kontributor reguler yang konsisten membagikan wawasan retail berkualitas.')
                ->update([
                    'description' => 'Kontributor reguler yang konsisten membagikan wawasan berkualitas.',
                    'updated_at' => now(),
                ]);

            DB::table('level_rules')
                ->where('description', 'Ahli operasional retail yang karyanya banyak diapresiasi dan disimpan.')
                ->update([
                    'description' => 'Ahli operasional yang karyanya banyak diapresiasi dan disimpan.',
                    'updated_at' => now(),
                ]);
        }

        if (Schema::hasTable('courses')) {
            $newSlugExists = DB::table('courses')
                ->where('slug', 'data-driven-analytics-dengan-excel')
                ->exists();

            $updateCourse = ['title' => 'Data-Driven Analytics dengan Excel', 'updated_at' => now()];
            if (! $newSlugExists) {
                $updateCourse['slug'] = 'data-driven-analytics-dengan-excel';
            }

            DB::table('courses')
                ->where('title', 'Data-Driven Retail dengan Excel')
                ->update($updateCourse);
        }

        if (Schema::hasTable('users')) {
            DB::table('users')
                ->where('location', 'Retail Store')
                ->update([
                    'location' => 'Store',
                    'updated_at' => now(),
                ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Intentional no-op: text cleanup should not restore removed wording.
    }
};

