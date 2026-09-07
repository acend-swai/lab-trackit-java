CREATE TABLE comment (
    id         BIGSERIAL PRIMARY KEY,
    task_id    BIGINT       NOT NULL REFERENCES task (id) ON DELETE CASCADE,
    author     VARCHAR(255) NOT NULL,
    body       VARCHAR(2000) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL
);

CREATE INDEX idx_comment_task_id ON comment (task_id);
