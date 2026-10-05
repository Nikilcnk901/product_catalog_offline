# Product Catalog & Offline Cart

## Overview

A Flutter application that loads a product catalog from DummyJSON and keeps a shopping cart on the device. Catalog screens need a network connection. The cart is stored locally and can be opened and edited without one.

## Features

- Product catalog
- Product search
- Product details
- Add to cart
- Quantity management
- Cart totals
- Persistent cart
- Offline cart functionality
- Error/loading/empty states

## Setup / Build Instructions

The project targets Dart SDK `^3.12.2`. It was developed with Flutter 3.44.6 (Dart 3.12.2).

1. Install Flutter 3.44 or a newer stable release that includes Dart 3.12.2.
2. Clone the repository and open the project directory:

```bash
git clone https://github.com/Nikilcnk901/product_catalog_offline.git
cd product_catalog_offline
```

3. Fetch packages:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

5. Build a release artifact for the target platform, for example:

```bash
flutter build apk
flutter build ios
flutter build web
```

## Architecture

MVVM-inspired architecture with BLoC/Cubit for presentation state management and Repository pattern for data access.

- **UI** (`views`, `widgets`): renders `ProductState` and `CartState`, sends user actions to the cubits, and does not call Dio or Hive.
- **Cubits** (`blocs`): `ProductCubit` loads and searches products. `CartCubit` loads the cart and applies every quantity change. Writes are applied one at a time.
- **Repository** (`data/repositories`): `ProductRepository` is the only product data source the cubit talks to.
- **Remote API** (`data/remote`): `ProductApi` calls DummyJSON with Dio and turns transport failures into short messages.
- **Local storage** (`data/local`): `CartStorage` reads and writes cart items with Hive. `CartCubit` is the only caller.

`ProductCubit` and `CartCubit` are created in `main.dart` and provided above `MaterialApp`.

## Project Structure

```text
lib/
├── core/
├── data/
├── models/
├── blocs/
├── views/
├── widgets/
└── main.dart
```

- `core/` holds the API paths, price formatting, and the Material theme.
- `data/` holds `ProductApi`, `ProductRepository`, and the Hive cart box.
- `models/` holds `Product` and `CartItem`. A cart line stores the product id, title, price, thumbnail, and quantity captured when the item was added.
- `blocs/` holds `ProductCubit` / `ProductState` and `CartCubit` / `CartState`.
- `views/` holds the product list, product details, and cart screens.
- `widgets/` holds shared pieces such as the product image, status message, and cart quantity control.
- `main.dart` initializes Hive, opens the cart box, and starts the two cubits.

## Libraries Used

- `flutter_bloc` — `Cubit`, `BlocProvider`, and the builders that subscribe the screens to state.
- `dio` — HTTP client for the DummyJSON product endpoints.
- `hive` — local box used to store the cart.
- `hive_flutter` — initializes Hive in the Flutter app directory.

## API

Product data comes from the DummyJSON Products API at `https://dummyjson.com`.

The app calls:

- `GET /products` for the catalog
- `GET /products/search?q=` for search
- `GET /products/{id}` for product details

No other DummyJSON endpoints are used.

## Local Storage Approach

Hive stores the cart. Each saved line is a `CartItem` written to the `cart` box under one key. Adding an item, changing its quantity, and removing it all go through `CartCubit`, which writes that list back to the box.

The cart does not need an internet connection. Those operations use the values already stored on the device.

Product catalog data is not persisted locally.

## Offline Support

After items have been added, the cart can be used with no connection:

- Existing cart items remain available without internet.
- Quantity changes work offline.
- Removing items works offline.
- Totals work offline.
- The cart is still there after the application is closed and opened again, including when that restart happens offline.

`CartScreen` reads `CartCubit` only. It does not use `ProductRepository`, `ProductApi`, or a network call to show names, prices, quantities, or totals.

## Important Design Decisions

- Cubit was chosen because the state transitions are straightforward: a screen loads, succeeds, fails, or a cart line changes quantity.
- The repository keeps DummyJSON and Dio out of the screens. The cubit depends on `ProductRepository`, not on request setup.
- Hive is used because only the cart needs to be stored. A database is unnecessary for one list of cart lines.
- `CartState` is the single source of truth for cart quantities and totals. Product cards, search results, product details, and the cart screen all read that state. There is no separate quantity value in those widgets.
- Product API failures are represented through presentation states. The API layer replaces Dio errors with a short message, and the screen shows that message with a retry action.
- Each catalog or search request has an id. A slower response from an earlier search is ignored, so it cannot replace a newer result. The search field waits 400ms after typing before sending a request, and it does not send the same query again.

## Error Handling

- **Network failure:** connection errors show “Check your connection and try again.”
- **Timeout:** connect, send, and receive timeouts use that same message.
- **API failure:** other HTTP failures show “The product service returned an unexpected response.” A missing product shows “That product could not be found.”
- **Empty catalog:** a successful response with no products shows “No products to show.”
- **Empty search results:** a search with no matches shows “No products match "…".”
- **Retry:** catalog, search, and product-details failures show a Retry button. A cart load failure shows one as well.

Raw Dio or socket messages are not shown. An empty search is an empty state, not an error. Clearing the search field loads the catalog again.

## Testing

`flutter analyze` reports no issues.

`flutter test` passes these tests:

- `test/cart_cubit_test.dart` uses a real Hive box and no network. It adds an item, restarts the cubit, checks that the item is still there, changes the quantity, restarts again, then decreases, removes, and restarts to confirm the stored cart.
- `test/widget_test.dart` covers adding a product and updating cart totals, keeping one quantity across the product list, search results, product details, and cart, an empty search returning to the catalog, and a connection error that can be retried without showing a raw exception.

## Known Limitations

Product catalog browsing requires network connectivity. The offline requirement is implemented for the shopping cart.

Cart rows keep the title, price, and thumbnail URL from the moment the product was added. They are not refreshed from DummyJSON later. The thumbnail is still loaded from that URL, so the picture may be missing offline; the stored name, price, quantity, and totals are not.

Quantity is not limited by the product’s stock count.
