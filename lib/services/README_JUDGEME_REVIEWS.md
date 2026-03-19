# Judge.me Reviews Integration

The Glocure app now includes comprehensive product reviews integration using Judge.me platform. This provides customers with authentic product reviews and ratings to make informed purchasing decisions.

## Features

- **Product Ratings**: Star ratings displayed below product price
- **Review Summary**: First 2 reviews shown on product details screen
- **Full Reviews Screen**: Dedicated screen showing all reviews with pagination
- **Review Images**: Support for customer-uploaded review photos
- **Verified Buyer Badge**: Shows if reviewer is a verified purchaser
- **Real-time Data**: Fetches latest reviews from Judge.me API

## Architecture

### Models (`lib/models/`)
- `judgeme_product_model.dart` - Judge.me product data with ratings
- `judgeme_reviews_model.dart` - Review data with pagination support

### Service (`lib/services/`)
- `judgeme_service.dart` - API client for Judge.me platform

### State Management (`lib/cubits/reviews/`)
- `reviews_cubit.dart` - Manages reviews state and pagination

### UI Components (`lib/widgets/`)
- `product_rating_widget.dart` - Star rating display below price
- `product_reviews_summary.dart` - Review cards for product details

### Screens (`lib/screens/`)
- `reviews_screen.dart` - Full reviews listing with pagination

## API Integration

### Judge.me API Configuration
- **Base URL**: `https://judge.me/api/v1`
- **Shop Domain**: `bxaqgp-p1.myshopify.com`
- **API Token**: `Ght5-t24nmY0x8e7EYDoyp26ca8`

### Two-Step Process

#### Step 1: Get Judge.me Product ID
```bash
curl "https://judge.me/api/v1/products/-1?shop_domain=bxaqgp-p1.myshopify.com&api_token=Ght5-t24nmY0x8e7EYDoyp26ca8&external_id=8595686588594"
```

#### Step 2: Get Product Reviews
```bash
curl "https://judge.me/api/v1/reviews?shop_domain=bxaqgp-p1.myshopify.com&api_token=Ght5-t24nmY0x8e7EYDoyp26ca8&product_id=1497539848&limit=10&page=1"
```

## User Experience

### Product Details Screen

**Star Rating Display:**
- Shows below product price
- Displays average rating (e.g., "4.5 (23 reviews)")
- Clickable to navigate to full reviews screen
- Hidden if no reviews available

**Review Summary:**
- Shows first 2 customer reviews
- Compact card design with reviewer info
- Star rating, review text, and date
- "View All Reviews" button if more exist
- Verified buyer badges when applicable

### Reviews Screen

**Full Review Listing:**
- All reviews with pagination
- Pull-to-refresh functionality
- Infinite scroll loading
- Review images in horizontal scroll
- Reviewer avatars with initials
- Formatted dates (e.g., "2 days ago")

**Review Card Features:**
- Reviewer name and avatar
- Star rating (1-5 stars)
- Review title and body text
- Customer photos
- Verified buyer badge
- Relative timestamps

## Implementation Details

### Product Details Integration

```dart
// Initialize reviews when product loads
final numericId = productId.contains('/') ? productId.split('/').last : productId;
context.read<ReviewsCubit>().fetchReviews(numericId);

// Display rating below price
ProductRatingWidget(
  product: reviewsState.product,
  onTap: () => Navigator.push(...),
)

// Show review summary below description
ProductReviewsSummary(
  productId: numericId,
  productName: product.title,
)
```

### Pagination Implementation

```dart
// Load more reviews on scroll
void _onScroll() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 200) {
    context.read<ReviewsCubit>().loadMoreReviews();
  }
}

// Cubit handles pagination state
Future<void> loadMoreReviews() async {
  if (!currentState.meta.hasNextPage) return;
  
  final nextPage = currentState.meta.currentPage + 1;
  final reviewsResponse = await _judgemeService.getProductReviews(
    productId: _currentJudgemeProductId!,
    page: nextPage,
  );
  
  // Combine existing + new reviews
  final allReviews = [...currentState.reviews, ...reviewsResponse.reviews];
}
```

### Error Handling

- **No Internet**: Connectivity checking before API calls
- **Product Not Found**: Graceful handling when no Judge.me product exists
- **API Errors**: User-friendly error messages with retry options
- **Empty Reviews**: "No Reviews Yet" state with encouraging message

## Data Flow

1. **Product Details Load**: Extract Shopify product ID
2. **Judge.me Lookup**: Convert Shopify ID to Judge.me product ID
3. **Reviews Fetch**: Get reviews using Judge.me product ID
4. **State Update**: Update UI with reviews and ratings
5. **Pagination**: Load more reviews on demand

## Benefits

- **Social Proof**: Customer reviews build trust and confidence
- **Informed Decisions**: Ratings help customers choose products
- **User Engagement**: Review photos and detailed feedback
- **SEO Value**: Rich review content improves search visibility
- **Conversion**: Reviews typically increase purchase rates

## Testing Scenarios

### Test Product with Reviews
1. Navigate to product details screen
2. Verify star rating appears below price
3. Check review summary shows 2 reviews max
4. Tap "View All Reviews" to see full screen
5. Test pagination by scrolling to bottom

### Test Product without Reviews
1. Navigate to product without reviews
2. Verify no rating widget appears
3. Confirm no review summary section
4. Reviews screen should show "No Reviews Yet"

### Test Error Scenarios
1. Disable internet connection
2. Try loading reviews - should show error
3. Enable internet and retry - should work
4. Test with invalid product ID

The Judge.me Reviews integration provides a complete review system that enhances the shopping experience and builds customer confidence in product purchases.