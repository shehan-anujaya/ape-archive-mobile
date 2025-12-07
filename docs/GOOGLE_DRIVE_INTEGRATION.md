# Google Drive Integration Documentation

## Overview

The Ape Archive mobile app loads educational resources stored in Google Drive through the backend API server. The app **does not directly access Google Drive** - instead, it communicates with the backend server which handles all Google Drive authentication and file streaming.

## Architecture Flow

```
Flutter App → Backend API → Google Drive
     ↓            ↓              ↓
  Display    Authenticate   Store Files
  Content     & Stream
```

## How It Works

### 1. **Resource Listing**

**Endpoint:** `GET /api/v1/library/browse`

The app fetches a list of available resources:

```dart
// lib/features/library/data/repositories/library_repository.dart
Future<PaginatedResourceResponse> browseResources({
  String? stream,
  String? subject,
  String? grade,
  String? medium,
  String? resourceType,
  String? search,
  int page = 1,
  int limit = 20,
}) async {
  final response = await _dio.get(
    'https://server.apearchive.lk/api/v1/library/browse',
    queryParameters: queryParams,
  );
  // Returns list of resources with their Google Drive file IDs
}
```

**Response Structure:**
```json
{
  "data": {
    "data": [
      {
        "id": "resource-id",
        "title": "Biology Grade 11",
        "driveFileId": "1abc...xyz",  // Google Drive file ID
        "mimeType": "application/pdf",
        "fileSize": 2048000,
        "thumbnail": "https://...",
        "tags": [...],
        ...
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

### 2. **Hierarchy Browsing**

**Endpoint:** `GET /api/v1/library/hierarchy`

Fetches the organizational structure (Grade → Subject → Lesson → Medium):

```dart
Future<List<TagHierarchyNode>> getHierarchy() async {
  final response = await _dio.get(
    'https://server.apearchive.lk/api/v1/library/hierarchy',
  );
  // Returns hierarchical tag structure
}
```

### 3. **Resource Streaming**

**Endpoint:** `GET /api/v1/resources/{id}/stream`

When a user views a PDF, the app requests the file from the backend:

```dart
String getStreamingUrl(String resourceId) {
  return 'https://server.apearchive.lk/api/v1/resources/$resourceId/stream';
}
```

The backend:
1. Authenticates the user's request
2. Fetches the file from Google Drive using the `driveFileId`
3. Streams the content back to the app

**Usage in PDF Viewer:**
```dart
// lib/features/library/presentation/screens/resource_detail_screen.dart
SfPdfViewer.network(
  streamingUrl, // https://server.apearchive.lk/api/v1/resources/{id}/stream
  headers: {
    'Authorization': 'Bearer $token',
  },
)
```

## Authentication

All API requests include the user's JWT token in headers:

```dart
// lib/core/network/dio_client.dart
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

The backend validates this token before serving resources.

## Error Handling

The repository handles various error scenarios:

```dart
// Connection errors
if (e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.connectionError) {
  errorMessage = 'Cannot connect to server';
}

// Authentication errors
else if (e.response?.statusCode == 401) {
  errorMessage = 'Authentication required. Please sign in.';
}

// Not found
else if (e.response?.statusCode == 404) {
  errorMessage = 'Resources not found.';
}
```

## Key Files

### Backend Communication
- `lib/core/constants/api_constants.dart` - API endpoints and configuration
- `lib/core/network/dio_client.dart` - HTTP client with auth interceptor
- `lib/features/library/data/repositories/library_repository.dart` - API calls

### Models
- `lib/features/library/data/models/resource_model.dart` - Resource data structure
- `lib/features/library/data/models/tag_model.dart` - Tag hierarchy

### UI
- `lib/features/library/presentation/screens/library_browse_screen.dart` - Resource list
- `lib/features/library/presentation/screens/resource_detail_screen.dart` - Resource view
- `lib/features/resources/presentation/screens/pdf_viewer_screen.dart` - PDF viewer

## Important Notes

1. **No Direct Google Drive Access**: The app never directly accesses Google Drive APIs. All access is through the backend.

2. **Backend Handles Authentication**: Google Drive OAuth and service account authentication is managed server-side.

3. **Streaming for Performance**: Files are streamed rather than downloaded entirely, improving performance and reducing storage needs.

4. **Pagination**: Resources are paginated (default 20 per page) to improve load times.

5. **Caching**: The Dio client can cache responses to reduce redundant API calls.

## Debugging

Enable debug logging to see API requests:

```dart
// Already configured in dio_client.dart
PrettyDioLogger(
  requestHeader: true,
  requestBody: true,
  responseBody: true,
  responseHeader: false,
  error: true,
)
```

Debug output includes:
- 📚 Request URLs
- 📚 Query parameters
- 📚 Response status codes
- 📚 Response data types

## Testing Endpoints

You can test the API endpoints directly:

```bash
# Get hierarchy
curl https://server.apearchive.lk/api/v1/library/hierarchy

# Browse resources
curl "https://server.apearchive.lk/api/v1/library/browse?page=1&limit=20"

# Get specific resource
curl https://server.apearchive.lk/api/v1/resources/{id}

# Stream resource (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://server.apearchive.lk/api/v1/resources/{id}/stream
```

## Future Enhancements

Potential improvements:
- Offline caching of downloaded resources
- Background download queue
- Progress tracking for large files
- Thumbnail generation
- Search suggestions based on popular queries

## Web Platform Limitations

The web version of the app has specific limitations due to browser security policies (CORS):

### What Works on Web:
✅ Browse resources by hierarchy (Grade → Subject → Lesson)
✅ View resource metadata (title, description, tags, uploader, stats)
✅ Search and filter resources
✅ Share resource links
✅ Navigate the hierarchy selector

### What Doesn't Work on Web:
❌ Direct PDF viewing in the app
❌ PDF downloading through the app
❌ Streaming resources from backend

### Why PDF Viewing Fails on Web:

The backend server (`https://server.apearchive.lk`) streams PDFs with authentication headers, but browser security policies (CORS) prevent the PDF viewer from accessing these authenticated streams. This is a fundamental browser limitation, not an app bug.

**Technical Details:**
- SfPdfViewer.network requires direct HTTP access to PDF files
- Browser CORS policy blocks cross-origin requests with custom headers
- The backend would need to:
  1. Serve PDFs on same domain as web app, OR
  2. Configure CORS headers to allow authenticated requests, OR
  3. Use signed URLs with embedded credentials

### Web Implementation:

```dart
// lib/features/library/presentation/screens/resource_detail_screen.dart

// Conditional PDF viewing button
if (!kIsWeb)
  ElevatedButton.icon(
    onPressed: () => _viewPDF(context, resource, streamingUrl),
    icon: const Icon(Icons.visibility),
    label: const Text('View PDF'),
  ),

// Web notice displayed instead
if (kIsWeb)
  Container(
    child: Column(
      children: [
        Icon(Icons.info_outline),
        Text('PDF Viewing Not Available on Web'),
        Text('Due to browser security restrictions (CORS)...'),
        // Alternative actions: Share, Copy Link
      ],
    ),
  ),
```

### Recommended User Flow for Web:

1. **Browse Hierarchy**: Users navigate Grade → Subject → Lesson
2. **View Details**: See resource information, tags, and metadata
3. **Share**: Copy link or share to mobile users
4. **Mobile Handoff**: Direct users to download mobile app for PDF viewing

The web version serves as a **catalog and discovery tool**, while the mobile app provides full resource access.
