-- Script de criação de tabelas para armazenar dados de instâncias
CREATE TABLE instances (
	id SERIAL PRIMARY KEY,
	provider VARCHAR(50),
	name VARCHAR(100),
	location VARCHAR(100),
	vm_size VARCHAR(50),
	os_type VARCHAR(50),
	ip_address VARCHAR(50)
);
