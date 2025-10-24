-- create database 'postgres' already created by env, create 'login' table
CREATE TABLE IF NOT EXISTS public.login (
  username varchar(100) PRIMARY KEY,
  password varchar(100) NOT NULL
);
-- do NOT insert any rows; initial table must be empty
