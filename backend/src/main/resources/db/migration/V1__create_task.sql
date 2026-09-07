CREATE TABLE task (
    id      BIGSERIAL PRIMARY KEY,
    title   VARCHAR(255) NOT NULL,
    project VARCHAR(255) NOT NULL,
    status  VARCHAR(16)  NOT NULL
);
