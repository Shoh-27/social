# Laravel Docker Production-Ready Environment

Complete Docker environment for Laravel with PostgreSQL, MongoDB, Redis, and WebSockets.

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- At least 4GB RAM allocated to Docker

### Initial Setup

```bash
# 1. Make setup script executable
chmod +x setup.sh

# 2. Run setup (creates directories and installs Laravel)
./setup.sh

# 3. Copy environment file
cp .env src/.env

# 4. Start all containers
docker-compose up -d

# 5. Wait for all services to be healthy (30-60 seconds)
docker-compose ps
```

---

## 📦 Post-Installation Commands

Run these commands **in order** after `docker-compose up -d`:

```bash
# 1. Generate application key
docker-compose exec app php artisan key:generate

# 2. Install Laravel Sanctum (API authentication)
docker-compose exec app composer require laravel/sanctum
docker-compose exec app php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# 3. Install MongoDB Laravel Package
docker-compose exec app composer require mongodb/laravel-mongodb

# 4. Install Laravel WebSockets
docker-compose exec app composer require beyondcode/laravel-websockets
docker-compose exec app php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="migrations"
docker-compose exec app php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="config"

# 5. Run PostgreSQL migrations
docker-compose exec app php artisan migrate

# 6. Create storage link
docker-compose exec app php artisan storage:link

# 7. Clear and cache configs
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache

# 8. Set permissions (if needed)
docker-compose exec app chown -R laravel:laravel /var/www/html/storage
docker-compose exec app chmod -R 775 /var/www/html/storage
docker-compose exec app chmod -R 775 /var/www/html/bootstrap/cache
```

---

## 🔧 Create MVP Features

After initial setup, create the MVP features:

```bash
# 1. Create controllers
docker-compose exec app php artisan make:controller Api/AuthController
docker-compose exec app php artisan make:controller Api/PostController
docker-compose exec app php artisan make:controller Api/ChatController

# 2. Create models
docker-compose exec app php artisan make:model Post -m
docker-compose exec app php artisan make:model Message

# 3. Create events for real-time broadcasting
docker-compose exec app php artisan make:event PostCreated
docker-compose exec app php artisan make:event MessageSent

# 4. Create migrations
docker-compose exec app php artisan make:migration create_posts_table

# 5. Run migrations
docker-compose exec app php artisan migrate

# 6. Create API routes (edit routes/api.php manually)
# See MVP_FEATURES.md for complete implementation
```

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Laravel App** | http://localhost | - |
| **WebSockets** | ws://localhost:6001 | - |
| **pgAdmin** | http://localhost:5050 | admin@laravel.local / admin123 |
| **Mongo Express** | http://localhost:8081 | admin / admin123 |
| **PostgreSQL** | localhost:5432 | laravel_user / laravel_secure_password |
| **MongoDB** | localhost:27017 | mongo_root / mongo_secure_password |
| **Redis** | localhost:6379 | redis_secure_password |

---

## 🔌 Service Details

### Laravel Application (PHP-FPM)
- **Container**: `laravel_app`
- **Port**: 9000 (internal)
- **Extensions**: PostgreSQL, MongoDB, Redis, BCMath, PCNTL, Sockets

### Queue Worker
- **Container**: `laravel_queue`
- **Command**: `php artisan queue:work --sleep=3 --tries=3`
- **Purpose**: Process background jobs

### WebSockets Server
- **Container**: `laravel_websockets`
- **Port**: 6001
- **Command**: `php artisan websockets:serve`
- **Purpose**: Real-time broadcasting

### PostgreSQL
- **Container**: `laravel_postgres`
- **Port**: 5432
- **Database**: laravel_db
- **Usage**: Users, Posts, Authentication

### MongoDB
- **Container**: `laravel_mongo`
- **Port**: 27017
- **Database**: laravel_chat
- **Usage**: Chat messages

### Redis
- **Container**: `laravel_redis`
- **Port**: 6379
- **Usage**: Cache, Queue, Session, Broadcasting

---

## 🧪 Testing the Setup

### Test Laravel is running
```bash
curl http://localhost
# Should return Laravel welcome page
```

### Test PostgreSQL connection
```bash
docker-compose exec app php artisan tinker
# Then run: DB::connection('pgsql')->getPdo();
```

### Test MongoDB connection
```bash
docker-compose exec app php artisan tinker
# Then run: DB::connection('mongodb')->getMongoClient();
```

### Test Redis connection
```bash
docker-compose exec app php artisan tinker
# Then run: Redis::ping();
```

### Test Queue Worker
```bash
# Dispatch a test job
docker-compose exec app php artisan queue:work --once

# Check queue worker logs
docker-compose logs -f queue
```

### Test WebSockets
```bash
# Check websockets server logs
docker-compose logs -f websockets

# Visit WebSockets dashboard
# http://localhost/laravel-websockets
```

---

## 🛠️ Useful Commands

### Container Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart app

# View logs
docker-compose logs -f app
docker-compose logs -f queue
docker-compose logs -f websockets

# Access container shell
docker-compose exec app sh
docker-compose exec app bash  # if bash is available
```

### Database Commands
```bash
# Run migrations
docker-compose exec app php artisan migrate

# Rollback migrations
docker-compose exec app php artisan migrate:rollback

# Seed database
docker-compose exec app php artisan db:seed

# Fresh database (drop + migrate + seed)
docker-compose exec app php artisan migrate:fresh --seed

# Access PostgreSQL CLI
docker-compose exec postgres psql -U laravel_user -d laravel_db

# Access MongoDB CLI
docker-compose exec mongo mongosh -u mongo_root -p mongo_secure_password
```

### Cache & Config
```bash
# Clear all caches
docker-compose exec app php artisan optimize:clear

# Cache config
docker-compose exec app php artisan config:cache

# Clear config cache
docker-compose exec app php artisan config:clear

# Cache routes
docker-compose exec app php artisan route:cache

# Clear route cache
docker-compose exec app php artisan route:clear
```

### Queue & Jobs
```bash
# List failed jobs
docker-compose exec app php artisan queue:failed

# Retry failed job
docker-compose exec app php artisan queue:retry {id}

# Retry all failed jobs
docker-compose exec app php artisan queue:retry all

# Clear all failed jobs
docker-compose exec app php artisan queue:flush
```

---

## 🗄️ Database Backups

### PostgreSQL Backup
```bash
# Backup
docker-compose exec postgres pg_dump -U laravel_user laravel_db > backup.sql

# Restore
docker-compose exec -T postgres psql -U laravel_user laravel_db < backup.sql
```

### MongoDB Backup
```bash
# Backup
docker-compose exec mongo mongodump --username mongo_root --password mongo_secure_password --authenticationDatabase admin --out /data/backup

# Restore
docker-compose exec mongo mongorestore --username mongo_root --password mongo_secure_password --authenticationDatabase admin /data/backup
```

---

## 🐛 Troubleshooting

### Permission Issues
```bash
# Fix storage permissions
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app chown -R laravel:laravel storage bootstrap/cache
```

### Port Already in Use
```bash
# Find process using port
lsof -i :80  # or :5432, :27017, etc.

# Change port in docker-compose.yml
# Example: "8080:80" instead of "80:80"
```

### Container Won't Start
```bash
# View container logs
docker-compose logs app

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Database Connection Failed
```bash
# Check database is running
docker-compose ps

# Check environment variables
docker-compose exec app env | grep DB_

# Test connection
docker-compose exec app php artisan tinker
```

### WebSockets Not Working
```bash
# Check websockets server is running
docker-compose logs websockets

# Restart websockets
docker-compose restart websockets

# Check Redis connection
docker-compose exec app php artisan tinker
# Then: Redis::ping();
```

---

## 📱 Kotlin Android Client Setup

### Add Dependencies
```gradle
// build.gradle
dependencies {
    implementation 'com.pusher:pusher-java-client:2.4.0'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
}
```

### API Configuration
```kotlin
object ApiConfig {
    const val BASE_URL = "http://YOUR_SERVER_IP/"
    const val WEBSOCKET_HOST = "YOUR_SERVER_IP"
    const val WEBSOCKET_PORT = 6001
    const val PUSHER_KEY = "local-app-key"
}
```

### Example API Service
```kotlin
interface ApiService {
    @POST("api/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>
    
    @POST("api/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>
    
    @GET("api/posts")
    suspend fun getPosts(): Response<List<Post>>
    
    @POST("api/posts")
    suspend fun createPost(@Body request: PostRequest): Response<Post>
    
    @POST("api/chat/send")
    suspend fun sendMessage(@Body request: MessageRequest): Response<Message>
    
    @GET("api/chat/{userId}")
    suspend fun getConversation(@Path("userId") userId: Int): Response<List<Message>>
}
```

---

## 🔒 Security Notes

**For Production:**
- Change all default passwords in `.env`
- Use strong, unique passwords for all services
- Enable HTTPS/SSL certificates
- Set `APP_DEBUG=false`
- Use proper firewall rules
- Implement rate limiting
- Enable Redis password authentication
- Use environment-specific credentials
- Implement proper CORS policies
- Enable Laravel's built-in security features

---

## 📚 Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Laravel WebSockets Docs](https://beyondco.de/docs/laravel-websockets)
- [MongoDB Laravel Driver](https://www.mongodb.com/docs/drivers/php/laravel-mongodb/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

## 📝 License

This Docker setup is open-source and available under the MIT License.
