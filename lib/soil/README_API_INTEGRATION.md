# Soil Measurement API Integration

This document describes the complete API integration for the Soil Measurement module.

## Architecture Overview

The implementation follows clean architecture principles with clear separation of concerns:

```
/soil
  /data
    soil_api_service.dart    # HTTP communication layer (Dio)
    soil_repository.dart     # Repository pattern implementation
  /models
    soil_measurement.dart    # Data model with JSON serialization
  /screens
    soil_measurements_list_screen.dart  # Main list view with provider
    soil_measurement_form_screen.dart   # Add/Edit form
    soil_measurement_details_screen.dart # Details view
  /widgets
    (reusable UI components)
```

## Key Components

### 1. API Service (`soil_api_service.dart`)

Handles all HTTP communication using Dio:

- **Base URL**: `http://localhost:3000/soil`
- **Features**:
  - Automatic request/response logging (PrettyDioLogger)
  - Comprehensive error handling with custom exceptions
  - Timeout configuration (30 seconds)
  - Type-safe DTOs for create/update operations

**Methods**:
- `getMeasurements()` - Fetch paginated list with filtering
- `getMeasurementById(id)` - Fetch single measurement
- `createMeasurement(dto)` - Create new measurement
- `updateMeasurement(id, dto)` - Update existing measurement
- `deleteMeasurement(id)` - Delete measurement

### 2. Repository (`soil_repository.dart`)

Provides a clean abstraction over the API service:

- Wraps API service methods with business logic
- Handles data transformation
- Provides convenience methods (getHealthyMeasurements, etc.)

### 3. Provider (`SoilMeasurementsProvider`)

State management using Provider pattern:

- Manages loading states
- Handles error messages
- Implements pagination
- Provides filtering capabilities
- Automatically updates UI on data changes

### 4. Data Model (`SoilMeasurement`)

Matches backend entity structure:

**Fields**:
- `id` (String) - UUID
- `ph` (double) - pH level (0-14)
- `soilMoisture` (double) - Moisture percentage (0-100)
- `sunlight` (double) - Sunlight intensity in lux
- `nutrients` (Map<String, dynamic>) - Nutrient values
- `temperature` (double) - Temperature in Celsius
- `latitude` (double) - GPS latitude
- `longitude` (double) - GPS longitude
- `createdAt` (DateTime) - Creation timestamp
- `updatedAt` (DateTime) - Last update timestamp

**Computed Properties**:
- `phStatus` - "Acidic", "Neutral", or "Alkaline"
- `moistureStatus` - "Dry", "Optimal", or "Wet"
- `isHealthy` - Boolean indicating overall health
- `healthScore` - Numeric health score (0-100)

## API Endpoints

### GET /soil
Fetch paginated list of measurements

**Query Parameters**:
- `page` (default: 1)
- `limit` (default: 10, max: 100)
- `minPh`, `maxPh` - pH range filter
- `minMoisture`, `maxMoisture` - Moisture range filter
- `minTemperature`, `maxTemperature` - Temperature range filter
- `sortBy` (default: "createdAt")
- `sortOrder` (default: "desc")

**Response**:
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "ph": 6.5,
      "soilMoisture": 45.5,
      "sunlight": 850.5,
      "nutrients": { "nitrogen": 20, "phosphorus": 15, "potassium": 25 },
      "temperature": 22.5,
      "latitude": 40.7128,
      "longitude": -74.006,
      "createdAt": "2026-02-14T12:00:00.000Z",
      "updatedAt": "2026-02-14T12:00:00.000Z"
    }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  }
}
```

### GET /soil/:id
Fetch single measurement by ID

**Response**: Single measurement object

### POST /soil
Create new measurement

**Request Body**:
```json
{
  "ph": 6.5,
  "soilMoisture": 45.5,
  "sunlight": 850.5,
  "nutrients": { "nitrogen": 20, "phosphorus": 15, "potassium": 25 },
  "temperature": 22.5,
  "latitude": 40.7128,
  "longitude": -74.006
}
```

**Response**: Created measurement object

### PATCH /soil/:id
Update existing measurement

**Request Body**: Partial measurement object (all fields optional)

**Response**: Updated measurement object

### DELETE /soil/:id
Delete measurement

**Response**: 204 No Content

## Error Handling

Custom exception handling with user-friendly messages:

**Exception Types**:
- `network` - Cannot connect to server
- `timeout` - Request timed out
- `notFound` - Resource not found (404)
- `validation` - Validation error (400)
- `server` - Server error (500+)
- `cancelled` - Request cancelled
- `unknown` - Unknown error

**User-Facing Error Messages**:
Errors are automatically converted to user-friendly messages and displayed in the UI via SnackBar.

## Usage Examples

### Basic List Screen Usage

```dart
// The provider is automatically created in the list screen
// No manual initialization needed
```

### Adding a Measurement

```dart
final provider = context.read<SoilMeasurementsProvider>();

final success = await provider.createMeasurement(
  ph: 6.5,
  soilMoisture: 45.5,
  sunlight: 850.5,
  nutrients: {
    'nitrogen': 20.0,
    'phosphorus': 15.0,
    'potassium': 25.0,
  },
  temperature: 22.5,
  latitude: 40.7128,
  longitude: -74.006,
);

if (success) {
  // Measurement created successfully
  // List automatically refreshes
}
```

### Updating a Measurement

```dart
final provider = context.read<SoilMeasurementsProvider>();

final success = await provider.updateMeasurement(
  id: measurementId,
  ph: 7.0,  // Only fields you want to update
);
```

### Deleting a Measurement

```dart
final provider = context.read<SoilMeasurementsProvider>();

final success = await provider.deleteMeasurement(measurementId);
```

### Filtering

```dart
final provider = context.read<SoilMeasurementsProvider>();

// Set filter
provider.setFilterStatus('Healthy'); // 'All', 'Healthy', or 'Warning'

// Filtered list is automatically computed
final filteredList = provider.filteredMeasurements;
```

## Configuration

### Changing Base URL

Edit `lib/soil/data/soil_api_service.dart`:

```dart
static const String baseUrl = 'http://your-server-address:3000/soil';
```

Or use the centralized config in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://your-server-address:3000';
  static String get soilEndpoint => '$baseUrl/soil';
}
```

### Timeout Settings

Adjust timeouts in `SoilApiService._createDio()`:

```dart
connectTimeout: const Duration(seconds: 30),
receiveTimeout: const Duration(seconds: 30),
```

### Pagination Settings

Default page size is 20. Change in `SoilMeasurementsProvider`:

```dart
int _limit = 20; // Change this value
```

## Testing

### Backend Requirements

Ensure your NestJS backend is running:

```bash
cd back/PIM_BACKEND
npm run start:dev
```

The API should be accessible at `http://localhost:3000/soil`

### Flutter App

```bash
cd front/PIM_FRONTEND
flutter pub get
flutter run
```

### Test Scenarios

1. **List View**: Should display all measurements with pagination
2. **Add**: Create new measurement → should appear in list
3. **Edit**: Update measurement → changes should reflect in list and details
4. **Delete**: Delete measurement → should remove from list
5. **Filtering**: Filter by health status → only matching items shown
6. **Error Handling**: Stop backend → should show connection error
7. **Pagination**: Scroll to bottom → should load more items

## Dependencies

```yaml
dependencies:
  dio: ^5.4.0
  pretty_dio_logger: ^1.3.1
  provider: ^6.1.2
  intl: ^0.19.0
```

## Security Considerations

For production:

1. **HTTPS**: Always use HTTPS in production
2. **API Keys**: Add API key authentication if needed
3. **Rate Limiting**: Implement rate limiting on backend
4. **Input Validation**: Validate all inputs before sending to API
5. **Token Storage**: Store auth tokens securely using secure_storage

## Future Enhancements

- [ ] Offline mode with local caching
- [ ] Real-time updates using WebSockets
- [ ] Batch operations
- [ ] Export to CSV/PDF
- [ ] Advanced filtering and search
- [ ] Image upload for measurements
- [ ] Integration with authentication module

## Troubleshooting

### "Cannot connect to server"

- Verify backend is running
- Check base URL configuration
- Ensure device/emulator can reach localhost
  - Android emulator: Use `http://10.0.2.2:3000`
  - iOS simulator: Use `http://localhost:3000`
  - Physical device: Use your computer's IP address

### "Validation errors"

- Check that all required fields are provided
- Verify field value ranges (pH: 0-14, moisture: 0-100, etc.)
- Check nutrients object format

### "Timeout errors"

- Increase timeout duration
- Check network connection
- Verify backend performance

## Support

For issues or questions, please contact the development team or check the main project README.
