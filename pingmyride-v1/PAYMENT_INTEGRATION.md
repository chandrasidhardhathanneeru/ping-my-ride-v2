# Razorpay Payment Integration

This document describes the Razorpay payment gateway integration for bus booking confirmations in PingMyRide.

## Overview

The payment integration has been implemented to ensure that bus bookings are only confirmed after successful payment. Users must complete the payment process through Razorpay before their booking is saved to the database.

## Changes Made

### 1. Dependencies Added
- Added `razorpay_flutter: ^1.3.7` to `pubspec.yaml`

### 2. Configuration File
- **File**: `lib/core/config/razorpay_config.dart`
- Contains Razorpay API credentials:
  - Key ID: `rzp_test_CVbypqu6YtbzvT`
  - Key Secret: `Qi0jllHSrENWlNxGl0QXbJC5`
- Default booking fee: ₹50.00
- Company name and theme configuration

### 3. Payment Page
- **File**: `lib/features/payment/payment_page.dart`
- New page to handle the complete payment flow
- Features:
  - Displays booking summary (bus details, route information, driver info)
  - Shows payment amount breakdown
  - Integrates Razorpay checkout
  - Handles payment success, failure, and external wallet scenarios
  - Creates booking only after successful payment

### 4. Booking Model Updates
- **File**: `lib/core/models/booking.dart`
- Added payment-related fields:
  - `paymentId`: Razorpay payment ID
  - `orderId`: Razorpay order ID
  - `signature`: Payment signature for verification
  - `amount`: Payment amount
- Updated `fromMap()`, `toMap()`, and `copyWith()` methods

### 5. Bus Service Updates
- **File**: `lib/core/services/bus_service.dart`
- Added new method: `bookBusWithPayment()`
- Accepts bus, route, and payment details
- Creates booking with payment information
- Maintains transactional integrity

### 6. Home Page Updates
- **File**: `lib/features/home/home_page.dart`
- Updated booking confirmation dialog to show booking fee
- Changed "Confirm" button to "Proceed to Payment"
- Added `_navigateToPayment()` method
- Navigates to payment page instead of directly creating booking
- Automatically switches to "My Bookings" tab after successful payment

## User Flow

1. User selects a bus and clicks "Book Now"
2. Confirmation dialog appears showing bus details and booking fee (₹50)
3. User clicks "Proceed to Payment"
4. Payment page loads with:
   - Booking summary
   - Payment details
   - "Proceed to Payment" button
5. User clicks "Proceed to Payment" to open Razorpay checkout
6. User completes payment through Razorpay (supports multiple payment methods)
7. On successful payment:
   - Booking is created in Firestore with payment details
   - User is redirected back to home page
   - Success message is displayed
   - "My Bookings" tab is automatically selected
8. On payment failure:
   - User is redirected back to home page
   - Error message is displayed
   - No booking is created

## Payment Methods Supported

Through Razorpay, users can pay using:
- Credit/Debit Cards
- Net Banking
- UPI
- Wallets (Paytm, PhonePe, Google Pay, etc.)
- EMI options

## Security Features

1. Payment verification through Razorpay signature
2. Transactional booking creation (prevents duplicate bookings)
3. Server-side timestamp for booking records
4. Payment details stored with booking for audit trail

## Testing

Use the Razorpay test credentials provided:
- Test Key ID: `rzp_test_CVbypqu6YtbzvT`
- Test Key Secret: `Qi0jllHSrENWlNxGl0QXbJC5`

For testing, use Razorpay test cards:
- Success: `4111 1111 1111 1111`
- Failure: `4111 1111 1111 1234`
- CVV: Any 3 digits
- Expiry: Any future date

## Production Deployment

Before deploying to production:
1. Replace test credentials with live Razorpay credentials
2. Update `RazorpayConfig` in `lib/core/config/razorpay_config.dart`
3. Test all payment scenarios thoroughly
4. Implement webhook verification for server-side payment confirmation (recommended)

## Next Steps (Optional Enhancements)

1. Add webhook integration for server-side payment verification
2. Implement refund functionality for cancelled bookings
3. Add payment history page
4. Generate PDF receipts for completed bookings
5. Add email notifications for payment confirmations
6. Implement dynamic pricing based on routes
7. Add promo code/discount functionality
