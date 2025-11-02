# MVP Features Implementation

## Architecture Overview

```
┌─────────────────┐
│  Kotlin Android │
│     Client      │
└────────┬────────┘
         │ HTTP/WebSocket
         ▼
┌─────────────────┐
│  NGINX Proxy    │
└────────┬────────┘
         │
         ├─────────────► Laravel App (PHP-FPM)
         │               ├─► PostgreSQL (users, posts)
         │               ├─► MongoDB (chat messages)
         │               └─► Redis (cache, queues)
         │
         └─────────────► WebSockets Server
                         └─► Redis (broadcasting)
```

---

## Feature 1: User Authentication (PostgreSQL)

### Database Table: `users`
```php
// Migration: 2024_01_01_000000_create_users_table.php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->rememberToken();
    $table->timestamps();
});
```

### API Endpoints
- `POST /api/register` - Register new user
- `POST /api/login` - Login user (returns Bearer token)
- `POST /api/logout` - Logout user
- `GET /api/user` - Get authenticated user

### Implementation
```php
// app/Http/Controllers/AuthController.php
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($credentials)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }
}
```

---

## Feature 2: Posts (PostgreSQL)

### Database Table: `posts`
```php
// Migration: 2024_01_01_000001_create_posts_table.php
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->text('content');
    $table->timestamps();
});
```

### API Endpoints
- `POST /api/posts` - Create a post
- `GET /api/posts` - Get all posts
- `GET /api/posts/{id}` - Get single post
- `DELETE /api/posts/{id}` - Delete post

### Implementation
```php
// app/Http/Controllers/PostController.php
use App\Models\Post;
use App\Events\PostCreated;

class PostController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'content' => 'required|string|max:5000',
        ]);

        $post = $request->user()->posts()->create($validated);
        $post->load('user');

        // Broadcast real-time event
        broadcast(new PostCreated($post))->toOthers();

        return response()->json($post, 201);
    }

    public function index()
    {
        $posts = Post::with('user')->latest()->paginate(20);
        return response()->json($posts);
    }
}
```

### Event Broadcasting
```php
// app/Events/PostCreated.php
class PostCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $post;

    public function __construct(Post $post)
    {
        $this->post = $post;
    }

    public function broadcastOn()
    {
        return new Channel('posts');
    }
}
```

---

## Feature 3: 1-1 Chat Messages (MongoDB)

### MongoDB Collection: `messages`
```javascript
{
  _id: ObjectId,
  sender_id: Integer,
  receiver_id: Integer,
  message: String,
  read: Boolean,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

### API Endpoints
- `POST /api/chat/send` - Send message
- `GET /api/chat/{userId}` - Get conversation with user
- `GET /api/chat/conversations` - Get all conversations

### Implementation
```php
// app/Models/Message.php
use MongoDB\Laravel\Eloquent\Model;

class Message extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'messages';
    
    protected $fillable = [
        'sender_id',
        'receiver_id',
        'message',
        'read',
    ];

    protected $casts = [
        'sender_id' => 'integer',
        'receiver_id' => 'integer',
        'read' => 'boolean',
    ];
}

// app/Http/Controllers/ChatController.php
use App\Models\Message;
use App\Events\MessageSent;

class ChatController extends Controller
{
    public function send(Request $request)
    {
        $validated = $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'message' => 'required|string|max:2000',
        ]);

        $message = Message::create([
            'sender_id' => $request->user()->id,
            'receiver_id' => $validated['receiver_id'],
            'message' => $validated['message'],
            'read' => false,
        ]);

        // Broadcast to receiver in real-time
        broadcast(new MessageSent($message))->toOthers();

        return response()->json($message, 201);
    }

    public function conversation($userId)
    {
        $currentUserId = auth()->id();

        $messages = Message::where(function($query) use ($currentUserId, $userId) {
            $query->where('sender_id', $currentUserId)
                  ->where('receiver_id', $userId);
        })->orWhere(function($query) use ($currentUserId, $userId) {
            $query->where('sender_id', $userId)
                  ->where('receiver_id', $currentUserId);
        })
        ->orderBy('created_at', 'asc')
        ->get();

        return response()->json($messages);
    }
}
```

### Event Broadcasting
```php
// app/Events/MessageSent.php
class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct($message)
    {
        $this->message = $message;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->message->receiver_id);
    }
}
```

---

## Feature 4: Real-Time WebSockets

### Configuration
All events are automatically broadcast through Laravel WebSockets using Redis.

### Client Connection (Kotlin Android)
```kotlin
// Example WebSocket connection
val options = PusherOptions().apply {
    setHost("your-server.com")
    wsPort = 6001
    wssPort = 6001
    isEncrypted = false
}

val pusher = Pusher("local-app-key", options)

// Subscribe to posts channel
val postsChannel = pusher.subscribe("posts")
postsChannel.bind("PostCreated") { event ->
    // Handle new post
}

// Subscribe to private chat channel
val chatChannel = pusher.subscribe("private-chat.${userId}")
chatChannel.bind("MessageSent") { event ->
    // Handle new message
}
```

---

## API Routes Summary

```php
// routes/api.php
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Posts
    Route::apiResource('posts', PostController::class);
    
    // Chat
    Route::prefix('chat')->group(function () {
        Route::post('/send', [ChatController::class, 'send']);
        Route::get('/{userId}', [ChatController::class, 'conversation']);
        Route::get('/conversations', [ChatController::class, 'conversations']);
    });
});
```

---

## Database Connections Config

```php
// config/database.php
'connections' => [
    'pgsql' => [
        'driver' => 'pgsql',
        'host' => env('DB_HOST', 'postgres'),
        'port' => env('DB_PORT', '5432'),
        'database' => env('DB_DATABASE', 'laravel_db'),
        'username' => env('DB_USERNAME', 'laravel_user'),
        'password' => env('DB_PASSWORD', ''),
        'charset' => 'utf8',
        'prefix' => '',
        'schema' => 'public',
    ],
    
    'mongodb' => [
        'driver' => 'mongodb',
        'host' => env('MONGODB_HOST', 'mongo'),
        'port' => env('MONGODB_PORT', 27017),
        'database' => env('MONGODB_DATABASE', 'laravel_chat'),
        'username' => env('MONGODB_USERNAME', ''),
        'password' => env('MONGODB_PASSWORD', ''),
        'options' => [
            'database' => env('MONGODB_AUTH_DATABASE', 'admin'),
        ],
    ],
],
```