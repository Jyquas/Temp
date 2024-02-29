-- Users Table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL
);

-- Categories Table
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL
);

-- Questions Table
CREATE TABLE questions (
    question_id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL,
    "order" INT NOT NULL
);

-- Question Categories Table (for many-to-many relationship)
CREATE TABLE question_categories (
    question_category_id SERIAL PRIMARY KEY,
    question_id INT NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_question
        FOREIGN KEY(question_id) 
        REFERENCES questions(question_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_category
        FOREIGN KEY(category_id)
        REFERENCES categories(category_id)
        ON DELETE CASCADE
);

-- User Answers Table
CREATE TABLE user_answers (
    answer_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    question_id INT NOT NULL,
    answer BOOLEAN NOT NULL,
    CONSTRAINT fk_user
        FOREIGN KEY(user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_question_answer
        FOREIGN KEY(question_id)
        REFERENCES questions(question_id)
        ON DELETE CASCADE
);

-- Additional constraints and indexes could be added for optimization and to enforce business rules,
-- such as ensuring that a user can only answer a question once:
CREATE UNIQUE INDEX idx_user_question ON user_answers(user_id, question_id);
