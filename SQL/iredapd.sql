-- Track all in/out sessions.
/*
CREATE TABLE IF NOT EXISTS session_tracking (
    id BIGINT(20) UNSIGNED AUTO_INCREMENT,
    -- the current time in seconds since the Epoch
    time BIGINT NOT NULL,
    queue_id VARCHAR(255) NOT NULL DEFAULT '',
    client_address VARCHAR(255) NOT NULL DEFAULT '',
    client_name VARCHAR(255) NOT NULL DEFAULT '',
    reverse_client_name VARCHAR(255) NOT NULL DEFAULT '',
    helo_name VARCHAR(255) NOT NULL DEFAULT '',
    sender VARCHAR(255) NOT NULL DEFAULT '',
    recipient VARCHAR(255) NOT NULL DEFAULT '',
    recipient_count INT(10) UNSIGNED DEFAULT 0,
    instance VARCHAR(255) NOT NULL DEFAULT '',
    sasl_username VARCHAR(255) NOT NULL DEFAULT '',
    size BIGINT(20) UNSIGNED DEFAULT 0,
    encryption_protocol VARCHAR(255) NOT NULL DEFAULT '',
    encryption_cipher VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE INDEX session_tracking_time          ON session_tracking (time);
CREATE INDEX session_tracking_sender        ON session_tracking (sender);
CREATE INDEX session_tracking_recipient     ON session_tracking (recipient);
CREATE INDEX session_tracking_sasl_username ON session_tracking (sasl_username);
CREATE INDEX session_tracking_instance      ON session_tracking (instance);
CREATE INDEX session_tracking_idx1          ON session_tracking (queue_id, client_address, sender);
*/

-- Throttling.
-- Please check iRedAPD plugin `throttling` for more details.
CREATE TABLE throttle (
    id          BIGINT(20) UNSIGNED AUTO_INCREMENT,
    account     VARCHAR(255)            NOT NULL,

    -- 1: sender throttling
    -- 0: recipient throttling
    kind        TINYINT(1)              NOT NULL DEFAULT 1,

    priority    TINYINT(1) UNSIGNED     NOT NULL DEFAULT 0,
    period      INT(10) UNSIGNED        NOT NULL DEFAULT 0, -- Peroid, in seconds.

    -- throttle settings.
    --  * set value to `-1` to force check setting with lower priority
    --  * set value to `0` to unlimited, and stop checking settings with lower priority.
    msg_size    INT(10)                 NOT NULL DEFAULT -1, -- Limit of single (received) message size, in bytes.
    max_msgs    MEDIUMINT(8)            NOT NULL DEFAULT -1, -- Number of max (received) messages in total.
    max_quota   MEDIUMINT(8)            NOT NULL DEFAULT -1, -- Number of current (received) messages.

    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE UNIQUE INDEX account ON throttle (account);

-- *) how to track per-user throttle:
--
--    tid=`throttle.id`,
--    account=`[user_email_address]`
--
-- *) how to track user throttle for per-domain, subdomain, global settings:
--    (track throttle of each user under domain. for example, every user can
--     send 20 msgs in one minute)
--
--    tid=`throttle.id`,
--    account=`[user_email_address]`
--
-- *) how to track throttle for per-domain, subdomain, global settings:
--    (track throttle of all users under domain. for example, all users
--     together can send 20 msgs in one minute)
--
--    tid=`throttle.id`,
--    account=`[throttle_account]`  # e.g. @domain.com`, `@.domain.com`, `@.`
--
CREATE TABLE throttle_tracking (
    id          BIGINT(20) UNSIGNED AUTO_INCREMENT,
    -- foreign key of `throttle.id`
    tid         BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
    -- tracking account. e.g. user@domain, @domain, '@.'.
    account     VARCHAR(255)            NOT NULL DEFAULT '',    -- Sender or recipient

    -- Track accumulated msgs/quota since init tracking.
    cur_msgs    MEDIUMINT(8) UNSIGNED   NOT NULL DEFAULT 0, -- Number of current messages.
    cur_quota   INT(10) UNSIGNED        NOT NULL DEFAULT 0, -- Current accumulated message size in total, in bytes.

    -- Track initial and last tracking time
    init_time   INT(10) UNSIGNED        NOT NULL DEFAULT 0, -- The time we initial the throttling.
    last_time   INT(10) UNSIGNED        NOT NULL DEFAULT 0, -- The time we last track the throttling.

    PRIMARY KEY (id),
    FOREIGN KEY (tid) REFERENCES throttle (id)
) ENGINE=InnoDB;

CREATE UNIQUE INDEX tid_account ON throttle_tracking (tid, account);
