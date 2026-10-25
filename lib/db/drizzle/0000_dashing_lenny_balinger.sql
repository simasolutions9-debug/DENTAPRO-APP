CREATE TABLE `app_users` (
	`id` varchar(191) NOT NULL,
	`display_name` varchar(160),
	`status` enum('active','suspended') NOT NULL DEFAULT 'active',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `app_users_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `audit_logs` (
	`id` varchar(36) NOT NULL,
	`actor_user_id` varchar(191) NOT NULL,
	`scope_type` enum('platform','tenant','clinic','independent_practice','patient') NOT NULL,
	`scope_id` varchar(191),
	`action` varchar(100) NOT NULL,
	`subject_type` varchar(100) NOT NULL,
	`subject_id` varchar(191),
	`details` json,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `audit_logs_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `clinic_memberships` (
	`id` varchar(36) NOT NULL,
	`clinic_id` varchar(36) NOT NULL,
	`user_id` varchar(191) NOT NULL,
	`role` enum('clinic_admin','dentist','staff') NOT NULL,
	`status` enum('active','revoked') NOT NULL DEFAULT 'active',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `clinic_memberships_id` PRIMARY KEY(`id`),
	CONSTRAINT `clinic_memberships_clinic_user_uq` UNIQUE(`clinic_id`,`user_id`)
);
--> statement-breakpoint
CREATE TABLE `clinics` (
	`id` varchar(36) NOT NULL,
	`tenant_id` varchar(36) NOT NULL,
	`name` varchar(160) NOT NULL,
	`slug` varchar(100) NOT NULL,
	`city` varchar(120),
	`status` enum('active','suspended','archived') NOT NULL DEFAULT 'active',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `clinics_id` PRIMARY KEY(`id`),
	CONSTRAINT `clinics_tenant_slug_uq` UNIQUE(`tenant_id`,`slug`)
);
--> statement-breakpoint
CREATE TABLE `independent_practices` (
	`id` varchar(36) NOT NULL,
	`owner_user_id` varchar(191) NOT NULL,
	`name` varchar(160) NOT NULL,
	`city` varchar(120),
	`status` enum('active','suspended','archived') NOT NULL DEFAULT 'active',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `independent_practices_id` PRIMARY KEY(`id`),
	CONSTRAINT `independent_practices_owner_uq` UNIQUE(`owner_user_id`)
);
--> statement-breakpoint
CREATE TABLE `tenant_memberships` (
	`id` varchar(36) NOT NULL,
	`tenant_id` varchar(36) NOT NULL,
	`user_id` varchar(191) NOT NULL,
	`role` enum('tenant_admin','staff') NOT NULL,
	`status` enum('active','revoked') NOT NULL DEFAULT 'active',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `tenant_memberships_id` PRIMARY KEY(`id`),
	CONSTRAINT `tenant_memberships_tenant_user_uq` UNIQUE(`tenant_id`,`user_id`)
);
--> statement-breakpoint
CREATE TABLE `tenants` (
	`id` varchar(36) NOT NULL,
	`name` varchar(160) NOT NULL,
	`slug` varchar(100) NOT NULL,
	`status` enum('active','suspended','archived') NOT NULL DEFAULT 'active',
	`created_by_user_id` varchar(191) NOT NULL,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `tenants_id` PRIMARY KEY(`id`),
	CONSTRAINT `tenants_slug_uq` UNIQUE(`slug`)
);
--> statement-breakpoint
CREATE TABLE `user_roles` (
	`id` varchar(36) NOT NULL,
	`user_id` varchar(191) NOT NULL,
	`role` enum('super_admin','tenant_admin','dentist','patient') NOT NULL,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `user_roles_id` PRIMARY KEY(`id`),
	CONSTRAINT `user_roles_user_role_uq` UNIQUE(`user_id`,`role`)
);
--> statement-breakpoint
ALTER TABLE `audit_logs` ADD CONSTRAINT `audit_logs_actor_user_id_app_users_id_fk` FOREIGN KEY (`actor_user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `clinic_memberships` ADD CONSTRAINT `clinic_memberships_clinic_id_clinics_id_fk` FOREIGN KEY (`clinic_id`) REFERENCES `clinics`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `clinic_memberships` ADD CONSTRAINT `clinic_memberships_user_id_app_users_id_fk` FOREIGN KEY (`user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `clinics` ADD CONSTRAINT `clinics_tenant_id_tenants_id_fk` FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `independent_practices` ADD CONSTRAINT `independent_practices_owner_user_id_app_users_id_fk` FOREIGN KEY (`owner_user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `tenant_memberships` ADD CONSTRAINT `tenant_memberships_tenant_id_tenants_id_fk` FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `tenant_memberships` ADD CONSTRAINT `tenant_memberships_user_id_app_users_id_fk` FOREIGN KEY (`user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `tenants` ADD CONSTRAINT `tenants_created_by_user_id_app_users_id_fk` FOREIGN KEY (`created_by_user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `user_roles` ADD CONSTRAINT `user_roles_user_id_app_users_id_fk` FOREIGN KEY (`user_id`) REFERENCES `app_users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX `audit_logs_actor_created_idx` ON `audit_logs` (`actor_user_id`,`created_at`);--> statement-breakpoint
CREATE INDEX `audit_logs_scope_created_idx` ON `audit_logs` (`scope_type`,`scope_id`,`created_at`);--> statement-breakpoint
CREATE INDEX `clinic_memberships_user_status_idx` ON `clinic_memberships` (`user_id`,`status`);--> statement-breakpoint
CREATE INDEX `clinic_memberships_clinic_status_idx` ON `clinic_memberships` (`clinic_id`,`status`);--> statement-breakpoint
CREATE INDEX `clinics_tenant_status_idx` ON `clinics` (`tenant_id`,`status`);--> statement-breakpoint
CREATE INDEX `independent_practices_status_idx` ON `independent_practices` (`status`);--> statement-breakpoint
CREATE INDEX `tenant_memberships_user_status_idx` ON `tenant_memberships` (`user_id`,`status`);--> statement-breakpoint
CREATE INDEX `tenant_memberships_tenant_status_idx` ON `tenant_memberships` (`tenant_id`,`status`);--> statement-breakpoint
CREATE INDEX `tenants_status_idx` ON `tenants` (`status`);--> statement-breakpoint
CREATE INDEX `user_roles_user_idx` ON `user_roles` (`user_id`);