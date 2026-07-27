CREATE DATABASE IF NOT EXISTS glam_onboarding
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE glam_onboarding;

-- TABLE 1: tb_admins
CREATE TABLE IF NOT EXISTS tb_admins (
  id            INT           NOT NULL AUTO_INCREMENT,
  name          VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  NOT NULL,
  password_hash VARCHAR(255)  NOT NULL,
  role          ENUM('super_admin', 'ops', 'retention') NOT NULL DEFAULT 'retention',
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_admins_email (email),
  INDEX idx_admins_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TABLE 2: tb_clients
CREATE TABLE IF NOT EXISTS tb_clients (
  id                INT           NOT NULL AUTO_INCREMENT,
  name              VARCHAR(100)  NOT NULL,
  code              VARCHAR(20)   NOT NULL,
  description       TEXT,
  rate_per_order    DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
  avg_daily_earning DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
  payout_cycle      ENUM('weekly', 'fortnightly') NOT NULL DEFAULT 'weekly',
  bgv_owner         ENUM('glam', 'client') NOT NULL DEFAULT 'glam',
  is_active         TINYINT(1)   NOT NULL DEFAULT 1,
  created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_clients_code (code),
  INDEX idx_clients_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TABLE 3: tb_riders
CREATE TABLE IF NOT EXISTS tb_riders (
  id                 VARCHAR(36)   NOT NULL,
  full_name          VARCHAR(150)  NOT NULL,
  phone_number       VARCHAR(15)   NOT NULL,
  gender             ENUM('male', 'female', 'other') NOT NULL,
  city               VARCHAR(100)  NOT NULL,
  preferred_language ENUM('hindi', 'english', 'tamil', 'telugu', 'kannada', 'bengali', 'marathi') NOT NULL DEFAULT 'hindi',
  selected_client_id INT           DEFAULT NULL,
  glam_worker_code   VARCHAR(50)   DEFAULT NULL,
  assigned_hub_name  VARCHAR(150)  DEFAULT NULL,
  assigned_tl_name   VARCHAR(150)  DEFAULT NULL,
  assigned_tl_phone  VARCHAR(15)   DEFAULT NULL,
  onboarding_stage   ENUM('registered', 'documents_pending', 'documents_submitted', 'bgv_pending', 'bgv_cleared', 'onboarded', 'live') NOT NULL DEFAULT 'registered',
  bgv_status         ENUM('not_started', 'triggered', 'in_progress', 'cleared', 'rejected') NOT NULL DEFAULT 'not_started',
  is_live            TINYINT(1)   NOT NULL DEFAULT 0,
  created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_riders_phone (phone_number),
  UNIQUE KEY uq_riders_worker_code (glam_worker_code),
  INDEX idx_riders_stage (onboarding_stage),
  INDEX idx_riders_city (city),
  INDEX idx_riders_client (selected_client_id),
  INDEX idx_riders_bgv_status (bgv_status),

  CONSTRAINT fk_riders_client
    FOREIGN KEY (selected_client_id)
    REFERENCES tb_clients (id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TABLE 4: tb_documents
CREATE TABLE IF NOT EXISTS tb_documents (
  id               VARCHAR(36)  NOT NULL,
  rider_id         VARCHAR(36)  NOT NULL,
  document_type    ENUM('aadhaar', 'pan', 'vehicle_rc', 'driving_licence', 'bank_passbook', 'selfie') NOT NULL,
  file_path        VARCHAR(500) NOT NULL,
  file_name        VARCHAR(255) NOT NULL,
  mime_type        VARCHAR(100) NOT NULL,
  status           ENUM('pending', 'local_check_passed', 'verifying', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  rejection_reason VARCHAR(500) DEFAULT NULL,
  document_number  VARCHAR(50)  DEFAULT NULL,
  uploaded_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verified_at      TIMESTAMP    DEFAULT NULL,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  INDEX idx_docs_rider (rider_id),
  INDEX idx_docs_type (document_type),
  INDEX idx_docs_status (status),

  CONSTRAINT fk_docs_rider
    FOREIGN KEY (rider_id)
    REFERENCES tb_riders (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TABLE 5: tb_bgv
CREATE TABLE IF NOT EXISTS tb_bgv (
  id               INT          NOT NULL AUTO_INCREMENT,
  rider_id         VARCHAR(36)  NOT NULL,
  client_id        INT          NOT NULL,
  bgv_owner        ENUM('glam', 'client') NOT NULL DEFAULT 'glam',
  status           ENUM('triggered', 'in_progress', 'cleared', 'rejected') NOT NULL DEFAULT 'triggered',
  triggered_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cleared_at       TIMESTAMP    DEFAULT NULL,
  verified_at      TIMESTAMP    DEFAULT NULL,
  rejection_reason TEXT         DEFAULT NULL,
  remarks          TEXT         DEFAULT NULL,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_bgv_rider_client (rider_id, client_id),
  INDEX idx_bgv_rider (rider_id),
  INDEX idx_bgv_status (status),

  CONSTRAINT fk_bgv_rider
    FOREIGN KEY (rider_id)
    REFERENCES tb_riders (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_bgv_client
    FOREIGN KEY (client_id)
    REFERENCES tb_clients (id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TABLE 6: tb_notifications
CREATE TABLE IF NOT EXISTS tb_notifications (
  id         INT           NOT NULL AUTO_INCREMENT,
  rider_id   VARCHAR(36)   NOT NULL,
  type       ENUM('bgv_started', 'bgv_cleared', 'onboarding_complete', 'document_rejected', 'document_approved', 'payout_upcoming', 'payout_processed') NOT NULL,
  channel    ENUM('push', 'whatsapp', 'sms') NOT NULL DEFAULT 'whatsapp',
  status     ENUM('pending', 'sent', 'failed', 'delivered') NOT NULL DEFAULT 'pending',
  title      VARCHAR(255)  NOT NULL,
  body       TEXT          NOT NULL,
  payload    JSON          DEFAULT NULL,
  sent_at    TIMESTAMP     DEFAULT NULL,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  INDEX idx_notif_rider (rider_id),
  INDEX idx_notif_type (type),

  CONSTRAINT fk_notif_rider
    FOREIGN KEY (rider_id)
    REFERENCES tb_riders (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SEED DATA — 3 Active Clients
INSERT INTO tb_clients (name, code, description, rate_per_order, avg_daily_earning, payout_cycle, bgv_owner, is_active)
VALUES
  ('Flipkart Minutes', 'FKM', 'Ultra-fast delivery partner for Flipkart Minutes — 10-minute grocery delivery across top metro cities.', 32.00, 960.00, 'weekly', 'glam', 1),
  ('Zepto', 'ZEPTO', 'Quick-commerce delivery for Zepto stores. Earn weekly with high order density in metro areas.', 30.00, 900.00, 'weekly', 'glam', 1),
  ('Blinkit', 'BLINKIT', 'Blinkit quick-commerce partner. 10-minute deliveries with surge bonuses during peak hours.', 31.00, 930.00, 'weekly', 'glam', 1);
