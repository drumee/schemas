CREATE TABLE `quota` (
  `id` varbinary(16) NOT NULL,
  `size` decimal(12,1) NOT NULL DEFAULT 0.0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
