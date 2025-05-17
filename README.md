# PPChallenge - Store Application

[![Ruby Version](https://img.shields.io/badge/Ruby-3.x+-red.svg)](https://ruby-lang.org)
[![Rails Version](https://img.shields.io/badge/Rails-7.x+-red.svg)](https://rubyonrails.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)](https://www.postgresql.org)

A modern e-commerce platform built with Ruby on Rails and PostgreSQL.

## 📋 Prerequisites

- Ruby 3.4.4
- Rails 8.0.2
- PostgreSQL 15+
- ubuntu 24.04 (wsl)

## 🛠 Installation

### 1. Clone the repository
```bash
git clone https://github.com/nimplay/PPChalenge.git
cd PPChalenge
```

### 2. Set up database credentials
```
Create config/database.yml based on the example:

cp config/database.yml.example config/database.yml
Edit the file with your PostgreSQL credentials:

default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: your_username
  password: your_password
  host: localhost
  port: 5432
```
### 3. Install dependencies
```
bundle install
sudo install
```

###  4. Create and setup database
```
rails db:create
rails db:migrate
rails db:seed (Optional: Load sample data)
```

### 5. Configure environment variables
```
Create .env file:
cp .env.example .env
```
### 6. Start the application
```
rails server
The app will be available at http://localhost:3000

```
# 🚀 API Documentation
Access Swagger UI documentation at:
http://localhost:3000/api-docs/index.html

Key API Endpoints:

POST /api/v1/auth - Loggin

GET /api/v1/categories/most_purchased - List most purchased

GET /api/v1/categories/top_revenue - Top revenue

GET /api/v1/purchases/search{params} - Purchases search

GET /api/v1/purchases/statistics{params} - Purchases search

## 🧪 Testing

```
Run the test suite with:
rspec
bundle exec rake rswag:specs:swaggerize
```


## 📊 Database Schema
Database Schema
<img src="https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/Diagram-DB.png" alt="Diagrama de Base de Datos" width="800" style="display: block; margin: 0 auto;"/>



### 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.

### 📧 Contact

Nimrod Acosta - nimrod7day@gmail.com

Project Link: https://github.com/nimplay/PPChalenge
