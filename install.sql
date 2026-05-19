-- =============================================
-- QB-DETRAN - Sistema de Detran para QBCore
-- =============================================

-- Tabela de CNH
CREATE TABLE IF NOT EXISTS `detran_cnh` (
    `citizenid` VARCHAR(50) PRIMARY KEY,
    `validated` BOOLEAN DEFAULT 0,
    `validated_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Veículos
CREATE TABLE IF NOT EXISTS `detran_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(20) UNIQUE NOT NULL,
    `owner_name` VARCHAR(100) NOT NULL,
    `color` VARCHAR(50) NOT NULL,
    `description` TEXT NOT NULL,
    `ipva_debt` DECIMAL(10,2) DEFAULT 0.00,
    `last_ipva_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- OBSERVAÇÕES
-- =============================================
-- 1. As tabelas são criadas automaticamente pelo script server.lua
-- 2. Este arquivo SQL é apenas para instalação manual caso necessário
-- 3. Certifique-se de ter o oxmysql instalado e configurado
-- =============================================