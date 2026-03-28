# BrewMaster — Group 40 Contribution Tracker
## ALU Mobile Application Development

---

## Team Members

| Name | Role / Responsibility | Email |
|------|-----------------------|-------|
| Ryan Kelvin Wariebi Apreala | Integration Lead · Firebase Setup · Authentication · Profiles · Verification · Offline Sync · Testing | r.apreala@alustudent.com |
| Justine Neema | Listings · Search & Discovery · Map View · Listing Form | j.neema@alustudent.com |
| Clarisse Mukayiranga | Messaging · Real-time Chat · Push Notifications · Notification Centre | c.mukayiranga@alustudent.com |
| Elvis Kayonga | Payments · Escrow Flow · Flutterwave Integration · Currency Conversion · Transaction History | e.kayonga@alustudent.com |
| Adeline Claudia Iradukunda | Farmer & Buyer Dashboards · Market Prices · Analytics | a.iradukunda@alustudent.com |

---

## Task Allocation and Tracker

| Task Allocated | Assigned Member | Deadline | Completion Status | Reviewed by Team? | Comments |
|----------------|-----------------|----------|-------------------|-------------------|----------|
| Firebase project setup, `google-services.json`, Firestore rules | Ryan Kelvin Wariebi Apreala | 2026-01-20 | Completed | Yes | Includes App Check, offline persistence (40 MB cache) |
| Email/password registration and login (`AuthBloc`) | Ryan Kelvin Wariebi Apreala | 2026-01-28 | Completed | Yes | Email verification gate enforced before marketplace access |
| Google Sign-In and first-time profile setup screen | Ryan Kelvin Wariebi Apreala | 2026-01-31 | Completed | Yes | Redirects new Google users to role selection |
| User profile screen — view and edit, avatar upload | Ryan Kelvin Wariebi Apreala | 2026-02-07 | Completed | Yes | Avatar uploaded to Firebase Storage |
| Farmer verification workflow (KYC document upload) | Ryan Kelvin Wariebi Apreala | 2026-02-10 | Completed | Yes | Status: unverified → pending → verified/rejected |
| Navigation shell, routing (`app_router.dart`), `HomeShell` | Ryan Kelvin Wariebi Apreala | 2026-02-12 | Completed | Yes | Role-based bottom nav (farmer vs. buyer tabs) |
| Offline sync queue (`OfflineSyncRepository`, `ConnectivityBloc`) | Ryan Kelvin Wariebi Apreala | 2026-02-20 | Completed | Yes | Queues writes when offline, retries on reconnect |
| Voice assistant screen (`speech_to_text` v7) | Ryan Kelvin Wariebi Apreala | 2026-02-24 | Completed | Yes | Hands-free listing search; mic always visible |
| Localisation — English, Kinyarwanda, Swahili (`AppLocalizations`) | Ryan Kelvin Wariebi Apreala | 2026-02-28 | Completed | Yes | Language persisted in SharedPreferences |
| Dark mode (`ThemeNotifier`, Settings screen) | Ryan Kelvin Wariebi Apreala | 2026-03-05 | Completed | Yes | Persisted via SharedPreferences; no theme flash on cold start |
| Full integration test suite + CI fixes | Ryan Kelvin Wariebi Apreala | 2026-03-20 | Completed | Yes | 1,856 tests passing; 80.0% line coverage |
| Coffee listing CRUD (`ListingBloc`, `FirebaseListingRepository`) | Justine Neema | 2026-02-03 | Completed | Yes | Create, read, update, soft-delete (status → "expired") |
| Listing form screen — all technical fields + image upload | Justine Neema | 2026-02-07 | Completed | Yes | Variety, altitude, processing method, cupping score, certifications |
| Search and filter system (`SearchFilters`, `searchListings`) | Justine Neema | 2026-02-14 | Completed | Yes | Price, altitude, variety, processing method, region, certification |
| Listing detail screen — full spec view, price vs. market indicator | Justine Neema | 2026-02-18 | Completed | Yes | Highlights when asking price deviates from market average |
| Map view (OpenStreetMap via `flutter_map`) with listing pins | Justine Neema | 2026-03-10 | Completed | Yes | Tap pin → preview card; parses "lat,lng" and legacy formats |
| Saved Lots screen and heart-button save/unsave flow | Justine Neema | 2026-03-15 | Completed | Yes | Persisted to Firestore `savedListings` array on users doc |
| Real-time messaging (`MessagingBloc`, `FirebaseMessageRepository`) | Clarisse Mukayiranga | 2026-02-10 | Completed | Yes | `getOrCreateConversation` links buyer, farmer, and listing |
| Conversations list screen — unread count badges | Clarisse Mukayiranga | 2026-02-14 | Completed | Yes | Streams from Firestore; unread count denormalised on conv doc |
| Chat screen — message bubbles, send, mark-as-read | Clarisse Mukayiranga | 2026-02-18 | Completed | Yes | Speech-to-text mic button embedded in chat input |
| Push notifications (FCM token save, refresh) | Clarisse Mukayiranga | 2026-02-24 | Completed | Yes | Token stored on sign-in; refreshed on rotation |
| In-app notification centre (`NotificationBloc`) | Clarisse Mukayiranga | 2026-02-28 | Completed | Yes | Covers: new message, payment, listing saved, verification update |
| Notification bell with unread count badge (`NotificationBellButton`) | Clarisse Mukayiranga | 2026-03-03 | Completed | Yes | Displayed in app bar across all main screens |
| Flutterwave payment integration (checkout SDK) | Elvis Kayonga | 2026-02-14 | Completed | Yes | `paymentOptions: 'card, mobilemoneyrw, mpesa, ussd'` |
| Escrow state machine (`PaymentBloc`, `FirebasePaymentRepository`) | Elvis Kayonga | 2026-02-20 | Completed | Yes | 3-step: fundsHeld → delivered → completed |
| Currency conversion using `open.er-api.com` (`ExchangeRateService`) | Elvis Kayonga | 2026-02-24 | Completed | Yes | Converts USD to KES/RWF/UGX/TZS/ETB/BIF before Flutterwave charge |
| Transaction history screen — paginated list | Elvis Kayonga | 2026-02-28 | Completed | Yes | Filter by status; paginated via `getTransactionPage` |
| Transaction detail screen — status timeline, dispute, release funds | Elvis Kayonga | 2026-03-03 | Completed | Yes | PDF receipt export; full `statusHistory` audit trail |
| Payment screen — terms checkbox, escrow info, Flutterwave launch | Elvis Kayonga | 2026-03-07 | Completed | Yes | `isTestMode` derived from key prefix automatically |
| Farmer dashboard (`DashboardBloc`, `FirebaseDashboardRepository`) | Adeline Claudia Iradukunda | 2026-02-20 | Completed | Yes | Active listings, earnings, conversations, savedCount, response rate |
| Buyer dashboard | Adeline Claudia Iradukunda | 2026-02-24 | Completed | Yes | Total purchases, active conversations, saved listings count |
| Market price sync (`MarketPriceSyncService`, Stooq CSV parser) | Adeline Claudia Iradukunda | 2026-03-01 | Completed | Yes | Fetches Arabica (KC) and Robusta (RC) futures; writes to Firestore |
| Market prices screen — variety/grade breakdown | Adeline Claudia Iradukunda | 2026-03-05 | Completed | Yes | Available offline via Firestore persistence cache |

---

## Meeting Attendance Log

| Meeting Date | Agenda | Facilitator | Attendees | Key Discussion Points | Next Steps |
|--------------|--------|-------------|-----------|----------------------|------------|
| 2026-01-15 | Project kick-off: feature scope, architecture decisions, task allocation | Ryan Kelvin Wariebi Apreala | Ryan, Justine, Clarisse, Elvis, Adeline | Agreed on Clean Architecture + BLoC pattern; divided feature ownership; Firebase project created | Each member set up local Flutter environment; Ryan initialises repo |
| 2026-01-29 | Sprint 1 review: auth, listing skeleton, messaging scaffold | Ryan Kelvin Wariebi Apreala | Ryan, Justine, Clarisse, Elvis, Adeline | Auth flow demonstrated end-to-end; Firestore schema draft reviewed; agreed on `toJson`/`fromJson` field naming convention to match ERD | Justine completes listing form; Clarisse wires real-time stream; Elvis starts PaymentBloc |
| 2026-02-12 | Sprint 2 review: listings CRUD, messaging live, payment escrow draft | Justine Neema | Ryan, Justine, Clarisse, Elvis, Adeline | Listing search filters demoed; chat working end-to-end on device; escrow state machine reviewed; Flutterwave sandbox key tested | Elvis integrates Flutterwave SDK; Adeline starts dashboard queries; Ryan completes offline sync |
| 2026-02-26 | Sprint 3 review: Flutterwave integrated, dashboards live, voice assistant | Elvis Kayonga | Ryan, Justine, Clarisse, Elvis, Adeline | Full payment flow demo (sandbox): fundsHeld → delivered → completed; currency conversion shown for KES and RWF; dashboard metrics verified against Firestore data | Ryan adds localisation; Justine adds map view; Adeline polishes market prices screen |
| 2026-03-12 | Pre-submission review: test suite, coverage, flutter analyze, ERD audit | Ryan Kelvin Wariebi Apreala | Ryan, Justine, Clarisse, Elvis, Adeline | Reviewed `flutter analyze` output (0 issues); confirmed 1,856 tests passing at 80.0% coverage; ERD updated to reflect Flutterwave as single gateway and `savedListings` Firestore persistence; SUBMISSION.md finalised | Merge all branches to main; tag release commit; build release APK for demo |

---

*BrewMaster — Group 40 — ALU Mobile Application Development — March 28, 2026*
