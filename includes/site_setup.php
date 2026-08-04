<?php

function ensure_homepage_settings_table(PDO $pdo){
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS homepage_settings (
        setting_key VARCHAR(100) PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ");
}

function ensure_notifications_table(PDO $pdo){
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        application_id INTEGER NULL,
        sender_user_id INTEGER NULL,
        recipient_user_id INTEGER NULL,
        sender_role VARCHAR(30) DEFAULT 'admin',
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ");

    $columns = $pdo->query("
    SELECT column_name
    FROM information_schema.columns
    WHERE table_name = 'notifications'
    ")->fetchAll(PDO::FETCH_COLUMN);

    $requiredColumns = [
        'sender_user_id' => 'INTEGER NULL',
        'recipient_user_id' => 'INTEGER NULL',
        'sender_role' => "VARCHAR(30) DEFAULT 'admin'",
        'is_read' => 'BOOLEAN DEFAULT FALSE',
        'created_at' => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
    ];

    foreach($requiredColumns as $column => $definition){
        if(!in_array($column, $columns)){
            $pdo->exec("ALTER TABLE notifications ADD COLUMN $column $definition");
        }
    }
}

function get_homepage_settings(PDO $pdo){
    ensure_homepage_settings_table($pdo);

    $defaults = [
        'hero_title' => 'Study Abroad With Confidence',
        'hero_subtitle' => 'WorldPath helps students secure university admissions, visa guidance, document reviews, scholarship opportunities, and career development support worldwide.',
        'hero_primary_button' => 'Apply Now',
        'hero_secondary_button' => 'Book Consultation',
        'stat_one_number' => '500+',
        'stat_one_label' => 'Residents Trained',
        'stat_two_number' => '30+',
        'stat_two_label' => 'Students Mentored',
        'stat_three_number' => '3+',
        'stat_three_label' => 'Countries Served',
        'stat_four_number' => '4+',
        'stat_four_label' => 'University Placements',
        'cta_title' => 'Ready To Start Your Journey?',
        'cta_text' => 'Book a consultation today and discover your study abroad opportunities.',
        'cta_button' => 'Book Appointment'
    ];

    $stmt = $pdo->query("SELECT setting_key, setting_value FROM homepage_settings");
    $saved = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);

    return array_merge($defaults, $saved ?: []);
}

function save_homepage_settings(PDO $pdo, array $settings){
    ensure_homepage_settings_table($pdo);

    $stmt = $pdo->prepare("
    INSERT INTO homepage_settings (setting_key, setting_value, updated_at)
    VALUES (:setting_key, :setting_value, CURRENT_TIMESTAMP)
    ON CONFLICT (setting_key)
    DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = CURRENT_TIMESTAMP
    ");

    foreach($settings as $key => $value){
        $stmt->execute([
            'setting_key' => $key,
            'setting_value' => trim((string)$value)
        ]);
    }
}
