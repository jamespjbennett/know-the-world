# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_05_140009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "digests", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.date "published_on", null: false
    t.jsonb "sources", default: [], null: false
    t.string "status", default: "pending", null: false
    t.bigint "topic_subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_digests_on_status"
    t.index ["topic_subscription_id", "published_on"], name: "index_digests_on_topic_subscription_id_and_published_on", unique: true
    t.index ["topic_subscription_id"], name: "index_digests_on_topic_subscription_id"
  end

  create_table "fitness_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "recorded_on", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.bigint "topic_subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_subscription_id", "recorded_on"], name: "idx_on_topic_subscription_id_recorded_on_4547c2ad4b", unique: true
    t.index ["topic_subscription_id"], name: "index_fitness_snapshots_on_topic_subscription_id"
  end

  create_table "question_attempts", force: :cascade do |t|
    t.boolean "correct", null: false
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.bigint "quiz_id", null: false
    t.integer "selected_index", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["question_id"], name: "index_question_attempts_on_question_id"
    t.index ["quiz_id"], name: "index_question_attempts_on_quiz_id"
    t.index ["user_id", "question_id", "quiz_id"], name: "index_question_attempts_on_user_id_and_question_id_and_quiz_id", unique: true
    t.index ["user_id"], name: "index_question_attempts_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.integer "correct_index", null: false
    t.datetime "created_at", null: false
    t.bigint "digest_id"
    t.text "explanation", null: false
    t.jsonb "options", default: [], null: false
    t.text "prompt", null: false
    t.bigint "topic_subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["digest_id"], name: "index_questions_on_digest_id"
    t.index ["topic_subscription_id"], name: "index_questions_on_topic_subscription_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.bigint "question_id", null: false
    t.bigint "quiz_id", null: false
    t.boolean "review", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_quiz_questions_on_question_id"
    t.index ["quiz_id", "position"], name: "index_quiz_questions_on_quiz_id_and_position", unique: true
    t.index ["quiz_id", "question_id"], name: "index_quiz_questions_on_quiz_id_and_question_id", unique: true
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "digest_id", null: false
    t.integer "score"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["digest_id"], name: "index_quizzes_on_digest_id", unique: true
    t.index ["status"], name: "index_quizzes_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "topic_subscriptions", force: :cascade do |t|
    t.string "cadence", default: "daily", null: false
    t.datetime "created_at", null: false
    t.decimal "fitness_score", precision: 5, scale: 2, default: "0.0", null: false
    t.text "goal", null: false
    t.string "knowledge_level", default: "beginner", null: false
    t.datetime "last_activity_at"
    t.integer "streak_count", default: 0, null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "weekly_on", default: 0, null: false
    t.index ["topic_id"], name: "index_topic_subscriptions_on_topic_id"
    t.index ["user_id", "topic_id"], name: "index_topic_subscriptions_on_user_id_and_topic_id", unique: true
    t.index ["user_id"], name: "index_topic_subscriptions_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "curated", default: false, null: false
    t.text "description"
    t.string "name", null: false
    t.jsonb "profile", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["curated"], name: "index_topics_on_curated"
    t.index ["name"], name: "index_topics_on_name", unique: true, where: "(curated = true)"
    t.index ["user_id", "name"], name: "index_topics_on_user_id_and_name", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "digests", "topic_subscriptions"
  add_foreign_key "fitness_snapshots", "topic_subscriptions"
  add_foreign_key "question_attempts", "questions"
  add_foreign_key "question_attempts", "quizzes"
  add_foreign_key "question_attempts", "users"
  add_foreign_key "questions", "digests"
  add_foreign_key "questions", "topic_subscriptions"
  add_foreign_key "quiz_questions", "questions"
  add_foreign_key "quiz_questions", "quizzes"
  add_foreign_key "quizzes", "digests"
  add_foreign_key "sessions", "users"
  add_foreign_key "topic_subscriptions", "topics"
  add_foreign_key "topic_subscriptions", "users"
  add_foreign_key "topics", "users"
end
